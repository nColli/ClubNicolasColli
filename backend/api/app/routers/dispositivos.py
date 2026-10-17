from fastapi import APIRouter, Depends, HTTPException, status
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
        "Guarda el token de FCM del celular del usuario autenticado para enviarle "
        "avisos de sus reservas próximas. La app lo llama en cada inicio: si el "
        "token ya estaba registrado no se duplica, y si era de otro usuario (que "
        "usó el mismo celular) pasa a ser del usuario autenticado."
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

    dispositivo = db.get(models.Dispositivo, datos.token)
    if dispositivo is None:
        db.add(models.Dispositivo(token=datos.token, usuario_id=token["uid"]))
    else:
        dispositivo.usuario_id = token["uid"]
    db.commit()
    print(
        f"[push] Dispositivo {'nuevo' if dispositivo is None else 'ya registrado'} "
        f"{datos.token[:12]}... del usuario {token['uid']}",
        flush=True,
    )
