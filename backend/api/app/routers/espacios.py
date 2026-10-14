from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app import horarios, models
from app.database import get_db
from app.schemas import Disponibilidad, ErrorResponse, HoraDisponibilidad

router = APIRouter(prefix="/espacios", tags=["Espacios deportivos"])


@router.get(
    "/{espacio_id}/disponibilidad",
    response_model=Disponibilidad,
    summary="Disponibilidad de un espacio",
    description=(
        "Devuelve, para la fecha indicada, cada hora en que la sede del espacio está "
        "abierta y si está disponible para reservar. Una hora no está disponible si ya "
        "está reservada o si ya pasó."
    ),
    responses={
        404: {"model": ErrorResponse, "description": "El espacio no existe"},
    },
)
def obtener_disponibilidad(
    espacio_id: int,
    fecha: date = Query(description="Fecha a consultar (AAAA-MM-DD)"),
    db: Session = Depends(get_db),
) -> Disponibilidad:
    espacio = db.get(models.EspacioDeportivo, espacio_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="El espacio no existe."
        )

    ocupadas = horarios.horas_ocupadas(db, espacio.id, fecha)
    horas = sorted(
        {
            hora
            for h in horarios.horarios_del_dia(espacio.sede, fecha)
            for hora in range(h.hora_apertura, h.hora_cierre)
        }
    )

    return Disponibilidad(
        espacio_id=espacio.id,
        fecha=fecha,
        horas=[
            HoraDisponibilidad(
                hora=hora,
                disponible=hora not in ocupadas and horarios.es_futura(fecha, hora),
            )
            for hora in horas
        ],
    )
