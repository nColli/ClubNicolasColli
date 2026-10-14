import os
import secrets

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.firebase import get_firebase_user
from app.notificaciones import enviar_avisos_pendientes
from app.schemas import ErrorResponse, Notificacion, ResultadoAvisos

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


@router.post(
    "/enviar-pendientes",
    response_model=ResultadoAvisos,
    summary="Enviar avisos de reservas próximas",
    description=(
        "Envía los avisos push de 24 h y 1 h antes que correspondan en este momento. "
        "La API ya lo hace sola cada pocos minutos; este endpoint es para un cron "
        "externo, útil en Render (free), donde el servicio se suspende sin tráfico. "
        "Requiere el header `X-Cron-Secret` con el valor de la variable `CRON_SECRET`."
    ),
    responses={
        403: {"model": ErrorResponse, "description": "Falta el secreto o no coincide"},
    },
)
def enviar_pendientes(
    x_cron_secret: str | None = Header(None),
    db: Session = Depends(get_db),
) -> ResultadoAvisos:
    esperado = os.getenv("CRON_SECRET")
    if not esperado or not x_cron_secret or not secrets.compare_digest(
        x_cron_secret, esperado
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Secreto inválido."
        )
    return ResultadoAvisos(enviados=enviar_avisos_pendientes(db))
