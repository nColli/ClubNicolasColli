from fastapi import APIRouter, Depends, HTTPException, Query, status
from psycopg2.errors import ExclusionViolation
from sqlalchemy import Select, and_, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app import horarios, models, notificaciones
from app.database import get_db
from app.firebase import get_firebase_user
from app.schemas import ErrorResponse, Reserva, ReservaCreate

router = APIRouter(prefix="/reservas", tags=["Reservas"])

_HORARIO_OCUPADO = "El espacio ya está reservado en ese horario. Elegí otro."


def _consulta_reservas() -> Select:
    """Reservas con su espacio, sede y precio total, listas para devolver."""
    r, e, s = models.Reserva, models.EspacioDeportivo, models.Sede
    return (
        select(
            r.id,
            r.fecha,
            r.hora_inicio,
            r.hora_fin,
            (e.precio_hora * (r.hora_fin - r.hora_inicio)).label("precio_total"),
            e.id.label("espacio_id"),
            e.nombre.label("espacio_nombre"),
            e.tipo.label("espacio_tipo"),
            e.numero.label("espacio_numero"),
            s.id.label("sede_id"),
            s.nombre.label("sede_nombre"),
            s.direccion.label("sede_direccion"),
            s.imagen_url.label("sede_imagen_url"),
        )
        .join(e, e.id == r.espacio_id)
        .join(s, s.id == e.sede_id)
    )


@router.get(
    "",
    response_model=list[Reserva],
    summary="Listar reservas del usuario",
    description=(
        "Devuelve las reservas del usuario autenticado, con su sede y espacio deportivo. "
        "Con `proximas=true` devuelve solo las que todavía no terminaron, de la más cercana "
        "a la más lejana; si no, devuelve todo el historial, de la más reciente a la más antigua. "
        "Si el usuario no tiene reservas devuelve una lista vacía."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
    },
)
def listar_reservas(
    proximas: bool = Query(False, description="Solo reservas que todavía no terminaron"),
    limit: int | None = Query(None, ge=1, le=100, description="Cantidad máxima de reservas"),
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> list[Reserva]:
    r = models.Reserva
    consulta = _consulta_reservas().where(r.usuario_id == token["uid"]).limit(limit)

    if proximas:
        ahora = horarios.ahora()
        consulta = consulta.where(
            or_(
                r.fecha > ahora.date(),
                and_(r.fecha == ahora.date(), r.hora_fin > ahora.hour),
            )
        ).order_by(r.fecha, r.hora_inicio)
    else:
        consulta = consulta.order_by(r.fecha.desc(), r.hora_inicio.desc())

    return [Reserva.model_validate(fila._mapping) for fila in db.execute(consulta)]


@router.post(
    "",
    response_model=Reserva,
    status_code=status.HTTP_201_CREATED,
    summary="Reservar un espacio",
    description=(
        "Reserva un espacio deportivo para el usuario autenticado. El horario tiene que "
        "ser de horas completas, futuro y estar dentro del horario de la sede ese día. "
        "Si el espacio ya está reservado en un horario superpuesto devuelve 409."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        404: {"model": ErrorResponse, "description": "El espacio no existe o el usuario no está registrado"},
        409: {"model": ErrorResponse, "description": "El espacio ya está reservado en ese horario"},
        422: {"model": ErrorResponse, "description": "Horario pasado, fuera del horario de la sede o inválido"},
    },
)
def crear_reserva(
    datos: ReservaCreate,
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> Reserva:
    if db.get(models.Usuario, token["uid"]) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no registrado."
        )

    espacio = db.get(models.EspacioDeportivo, datos.espacio_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="El espacio no existe."
        )

    if not horarios.es_futura(datos.fecha, datos.hora_inicio):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Ese horario ya pasó. Elegí un horario futuro.",
        )

    if not horarios.dentro_del_horario(
        horarios.horarios_del_dia(espacio.sede, datos.fecha),
        datos.hora_inicio,
        datos.hora_fin,
    ):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="El horario está fuera del horario de atención de la sede.",
        )

    # Chequeo previo para dar un mensaje claro; la constraint
    # reserva_sin_superposicion cubre el caso de dos reservas simultáneas.
    ocupadas = horarios.horas_ocupadas(db, espacio.id, datos.fecha)
    if ocupadas & set(range(datos.hora_inicio, datos.hora_fin)):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=_HORARIO_OCUPADO)

    reserva = models.Reserva(
        espacio=espacio,
        usuario_id=token["uid"],
        fecha=datos.fecha,
        hora_inicio=datos.hora_inicio,
        hora_fin=datos.hora_fin,
    )
    db.add(reserva)
    try:
        # flush para tener el id de la reserva en la notificación; la
        # superposición se detecta acá
        db.flush()
        notificaciones.registrar(
            db,
            reserva.usuario_id,
            reserva.id,
            "Reserva confirmada",
            notificaciones.describir_reserva(reserva),
        )
        db.commit()
    except IntegrityError as e:
        db.rollback()
        if isinstance(e.orig, ExclusionViolation):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail=_HORARIO_OCUPADO
            )
        raise

    fila = db.execute(
        _consulta_reservas().where(models.Reserva.id == reserva.id)
    ).one()
    return Reserva.model_validate(fila._mapping)


@router.get(
    "/{reserva_id}",
    response_model=Reserva,
    summary="Detalle de una reserva",
    description=(
        "Devuelve una reserva del usuario autenticado. La app lo usa para abrir "
        "el detalle desde una notificación."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        404: {"model": ErrorResponse, "description": "La reserva no existe o es de otro usuario"},
    },
)
def obtener_reserva(
    reserva_id: int,
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> Reserva:
    r = models.Reserva
    fila = db.execute(
        _consulta_reservas().where(r.id == reserva_id, r.usuario_id == token["uid"])
    ).one_or_none()
    if fila is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="La reserva no existe."
        )
    return Reserva.model_validate(fila._mapping)


@router.delete(
    "/{reserva_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Cancelar una reserva",
    description=(
        "Cancela una reserva del usuario autenticado que todavía no empezó. "
        "La reserva se elimina, así que el espacio vuelve a quedar disponible "
        "en ese horario."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        404: {"model": ErrorResponse, "description": "La reserva no existe o es de otro usuario"},
        409: {"model": ErrorResponse, "description": "La reserva ya empezó o terminó"},
    },
)
def cancelar_reserva(
    reserva_id: int,
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> None:
    reserva = db.get(models.Reserva, reserva_id)
    # Una reserva de otro usuario se trata como inexistente, para no revelar
    # qué reservas existen
    if reserva is None or reserva.usuario_id != token["uid"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="La reserva no existe."
        )

    if not horarios.es_futura(reserva.fecha, reserva.hora_inicio):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="La reserva ya empezó o terminó, no se puede cancelar.",
        )

    notificaciones.registrar(
        db,
        reserva.usuario_id,
        None,  # la reserva se elimina
        "Reserva cancelada",
        notificaciones.describir_reserva(reserva),
    )
    db.delete(reserva)
    db.commit()

