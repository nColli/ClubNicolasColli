from fastapi import APIRouter, Depends
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app import horarios, models, notificaciones
from app.database import get_db
from app.firebase import get_firebase_user
from app.schemas import ErrorResponse, Notificacion

router = APIRouter(prefix="/notificaciones", tags=["Notificaciones"])


@router.get(
    "",
    response_model=list[Notificacion],
    summary="Notificaciones del usuario",
    description=(
        "Devuelve los recordatorios de las reservas del usuario autenticado que "
        "todavía no empezaron y ya tienen un aviso enviado (24 h o 1 h antes), "
        "de la más cercana a la más lejana. No se guardan: el título y el cuerpo "
        "se arman en el momento."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
    },
)
def listar_notificaciones(
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> list[Notificacion]:
    ahora = horarios.ahora()
    r = models.Reserva
    reservas = db.scalars(
        select(r)
        .where(
            r.usuario_id == token["uid"],
            or_(r.aviso_24h_enviado.is_(True), r.aviso_1h_enviado.is_(True)),
            # Igual que horarios.es_futura: que todavía no haya empezado
            or_(
                r.fecha > ahora.date(),
                and_(r.fecha == ahora.date(), r.hora_inicio > ahora.hour),
            ),
        )
        .order_by(r.fecha, r.hora_inicio)
    ).all()
    return [
        Notificacion(
            reserva_id=reserva.id,
            titulo=notificaciones.titulo_aviso(reserva, ahora),
            cuerpo=notificaciones.describir_reserva(reserva),
        )
        for reserva in reservas
    ]
