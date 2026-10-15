from fastapi import APIRouter, Depends, HTTPException, Response, status
from firebase_admin import auth, exceptions
from psycopg2.errors import UniqueViolation
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.firebase import get_firebase_user
from app.schemas import ErrorResponse, Usuario, UsuarioCreate, UsuarioUpdate

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])

_DNI_REPETIDO = "Ya hay un usuario registrado con ese DNI."


def _es_dni_repetido(error: IntegrityError) -> bool:
    return (
        isinstance(error.orig, UniqueViolation)
        and error.orig.diag.constraint_name == "usuario_dni_unico"
    )


@router.post(
    "",
    response_model=Usuario,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar un usuario",
    description=(
        "Registra en la base el perfil de un usuario recién creado en Firebase. "
        "Requiere el ID token de Firebase en el header `Authorization: Bearer <token>`. "
        "El `uid` y el `email` del body deben coincidir con los del token."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        403: {"model": ErrorResponse, "description": "El uid o el email no coinciden con el token"},
        409: {"model": ErrorResponse, "description": "Usuario o DNI ya registrado"},
    },
)
def registrar_usuario(
    datos: UsuarioCreate,
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> Usuario:
    email_token = (token.get("email") or "").lower()
    if token["uid"] != datos.uid or email_token != datos.email.lower():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="El uid o el email no corresponden al usuario autenticado",
        )

    usuario = models.Usuario(
        uid=datos.uid,
        email=email_token,
        nombre=datos.nombre,
        apellido=datos.apellido,
        dni=datos.dni,
        fecha_nacimiento=datos.fecha_nacimiento,
    )
    db.add(usuario)
    try:
        db.commit()
    except IntegrityError as e:
        db.rollback()
        if _es_dni_repetido(e):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail=_DNI_REPETIDO
            )
        if isinstance(e.orig, UniqueViolation):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El usuario ya está registrado.",
            )
        raise

    return Usuario.model_validate(usuario)


@router.get(
    "/me",
    response_model=Usuario,
    summary="Perfil del usuario autenticado",
    description="Devuelve el perfil del usuario identificado por el ID token de Firebase.",
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        404: {"model": ErrorResponse, "description": "El usuario no está registrado en la base"},
    },
)
def obtener_perfil(
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> Usuario:
    return Usuario.model_validate(_usuario_registrado(db, token["uid"]))


@router.put(
    "/me",
    response_model=Usuario,
    summary="Editar el perfil del usuario autenticado",
    description=(
        "Actualiza el nombre, el apellido, el DNI y la fecha de nacimiento del usuario "
        "identificado por el ID token de Firebase. El email no se puede modificar."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        404: {"model": ErrorResponse, "description": "El usuario no está registrado en la base"},
        409: {"model": ErrorResponse, "description": "El DNI es de otro usuario"},
        422: {"model": ErrorResponse, "description": "Datos inválidos (campos vacíos, DNI inválido, fecha futura)"},
    },
)
def actualizar_perfil(
    datos: UsuarioUpdate,
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> Usuario:
    usuario = _usuario_registrado(db, token["uid"])
    usuario.nombre = datos.nombre
    usuario.apellido = datos.apellido
    usuario.dni = datos.dni
    usuario.fecha_nacimiento = datos.fecha_nacimiento
    try:
        db.commit()
    except IntegrityError as e:
        db.rollback()
        if _es_dni_repetido(e):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail=_DNI_REPETIDO
            )
        raise

    return Usuario.model_validate(usuario)


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Dar de baja la cuenta del usuario autenticado",
    description=(
        "Elimina al usuario de la base (junto con sus reservas, dispositivos y "
        "notificaciones) y su cuenta de Firebase. No se puede deshacer."
    ),
    responses={
        401: {"model": ErrorResponse, "description": "Token ausente, inválido o expirado"},
        404: {"model": ErrorResponse, "description": "El usuario no está registrado en la base"},
        502: {"model": ErrorResponse, "description": "No se pudo eliminar la cuenta de Firebase"},
    },
)
def eliminar_cuenta(
    token: dict = Depends(get_firebase_user),
    db: Session = Depends(get_db),
) -> Response:
    usuario = _usuario_registrado(db, token["uid"])
    # RESERVA no tiene ON DELETE CASCADE; dispositivos y notificaciones sí
    db.query(models.Reserva).filter(models.Reserva.usuario_id == usuario.uid).delete()
    db.delete(usuario)
    db.flush()

    # Se borra de Firebase antes del commit: si falla, la base queda como estaba
    try:
        auth.delete_user(usuario.uid)
    except auth.UserNotFoundError:
        pass
    except exceptions.FirebaseError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudo eliminar la cuenta. Intentá de nuevo más tarde.",
        )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


def _usuario_registrado(db: Session, uid: str) -> models.Usuario:
    usuario = db.get(models.Usuario, uid)
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no registrado",
        )
    return usuario
