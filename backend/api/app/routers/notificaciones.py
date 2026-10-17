from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.firebase import get_firebase_user
from app.schemas import ErrorResponse, Notificacion

router = APIRouter(prefix="/notificaciones", tags=["Notificaciones"])


@router.get(
    "",
    response_model=list[Notificacion],
    summary="Notificaciones del usuario",
    description=(
        "Devuelve las notificaciones del usuario autenticado (reservas confirmadas "
        "y canceladas, y recordatorios), de la más nueva a la más vieja."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
    },
)
def listar_notificaciones(
    limit: int = Query(30, ge=1, le=100, description="Cantidad máxima"),
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> list[Notificacion]:
    n = models.Notificacion
    notificaciones = db.scalars(
        select(n)
        .where(n.usuario_id == token["uid"])
        .order_by(n.creada.desc(), n.id.desc())
        .limit(limit)
    ).all()
    return [Notificacion.model_validate(x) for x in notificaciones]


@router.post(
    "/leidas",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Marcar todas como leídas",
    description="Marca como leídas todas las notificaciones del usuario autenticado.",
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
    },
)
def marcar_leidas(
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> None:
    n = models.Notificacion
    db.execute(
        update(n).where(n.usuario_id == token["uid"], n.leida.is_(False)).values(leida=True)
    )
    db.commit()
