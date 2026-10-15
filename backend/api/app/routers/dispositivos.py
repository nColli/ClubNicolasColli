from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.firebase import get_firebase_user
from app.schemas import DispositivoCreate, ErrorResponse

router = APIRouter(prefix="/dispositivos", tags=["Notificaciones"])


@router.post(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Registrar un dispositivo para notificaciones",
    description=(
        "Guarda el token de FCM del dispositivo del usuario autenticado para "
        "enviarle avisos de sus reservas próximas. Si el token ya estaba "
        "registrado (por ejemplo, por otro usuario en el mismo celular), pasa a "
        "ser del usuario autenticado."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        404: {"model": ErrorResponse, "description": "El usuario no está registrado en la base"},
    },
)
def registrar_dispositivo(
    datos: DispositivoCreate,
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> None:
    if db.get(models.Usuario, token["uid"]) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no registrado."
        )
    # Upsert atómico: al iniciar sesión la app puede registrar el mismo token
    # dos veces a la vez (getToken y onTokenRefresh), y con un SELECT + INSERT
    # las dos requests intentarían insertarlo
    valores = {
        "token": datos.token,
        "usuario_id": token["uid"],
        "actualizado": datetime.now(timezone.utc),
    }
    db.execute(
        insert(models.Dispositivo)
        .values(**valores)
        .on_conflict_do_update(
            index_elements=[models.Dispositivo.token],
            set_={"usuario_id": valores["usuario_id"], "actualizado": valores["actualizado"]},
        )
    )
    db.commit()


@router.delete(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Quitar un dispositivo",
    description=(
        "Deja de enviar notificaciones al dispositivo (se usa al cerrar sesión). "
        "Si el token no está registrado para el usuario autenticado no hace nada."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
    },
)
def quitar_dispositivo(
    fcm_token: str = Query(alias="token", description="Token de FCM del dispositivo"),
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> None:
    db.query(models.Dispositivo).filter(
        models.Dispositivo.token == fcm_token,
        models.Dispositivo.usuario_id == token["uid"],
    ).delete()
    db.commit()
