from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app import models
from app.database import get_db
from app.schemas import EspacioDeportivo, ErrorResponse, HorarioSede, Sede

router = APIRouter(prefix="/sedes", tags=["Sedes"])


@router.get(
    "",
    response_model=list[Sede],
    summary="Listar sedes",
    description=(
        "Devuelve las sedes con sus horarios de funcionamiento y los tipos de "
        "espacios deportivos que ofrecen (Fútbol, Tenis, etc.)."
    ),
)
def listar_sedes(db: Session = Depends(get_db)) -> list[Sede]:
    sedes = db.scalars(
        select(models.Sede)
        .options(
            selectinload(models.Sede.horarios),
            selectinload(models.Sede.espacios),
        )
        .order_by(models.Sede.nombre)
    ).all()

    return [
        Sede(
            id=s.id,
            nombre=s.nombre,
            direccion=s.direccion,
            imagen_url=s.imagen_url,
            deportes=sorted({e.tipo for e in s.espacios}),
            horarios=[HorarioSede.model_validate(h) for h in s.horarios],
        )
        for s in sedes
    ]


@router.get(
    "/{sede_id}/espacios",
    response_model=list[EspacioDeportivo],
    summary="Listar espacios de una sede",
    description=(
        "Devuelve los espacios deportivos de la sede, ordenados por tipo y número, "
        "con su precio por hora."
    ),
    responses={
        404: {"model": ErrorResponse, "description": "La sede no existe"},
    },
)
def listar_espacios(sede_id: int, db: Session = Depends(get_db)) -> list[EspacioDeportivo]:
    if db.get(models.Sede, sede_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="La sede no existe."
        )

    espacios = db.scalars(
        select(models.EspacioDeportivo)
        .where(models.EspacioDeportivo.sede_id == sede_id)
        .order_by(models.EspacioDeportivo.tipo, models.EspacioDeportivo.numero)
    ).all()

    return [EspacioDeportivo.model_validate(e) for e in espacios]
