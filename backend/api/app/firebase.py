import os

import firebase_admin
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth, credentials

_bearer = HTTPBearer(auto_error=False)


def init_firebase() -> None:
    """Inicializa Firebase Admin con la cuenta de servicio, a partir de los tres
    datos del JSON que hacen falta (así el JSON no se sube al repositorio)."""
    variables = ("FIREBASE_PROJECT_ID", "FIREBASE_CLIENT_EMAIL", "FIREBASE_PRIVATE_KEY")
    faltan = [v for v in variables if not os.getenv(v)]
    if faltan:
        raise RuntimeError(f"Faltan variables de entorno: {', '.join(faltan)}")

    cred = credentials.Certificate(
        {
            "type": "service_account",
            "project_id": os.environ["FIREBASE_PROJECT_ID"],
            "client_email": os.environ["FIREBASE_CLIENT_EMAIL"],
            # Si la clave se cargó en una sola línea, los saltos vienen como "\n"
            "private_key": os.environ["FIREBASE_PRIVATE_KEY"].replace("\\n", "\n"),
            "token_uri": "https://oauth2.googleapis.com/token",
        }
    )
    firebase_admin.initialize_app(cred)


def get_firebase_user(
    creds: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> dict:
    """Valida el ID token de Firebase enviado en 'Authorization: Bearer <token>'
    y devuelve sus claims (uid, email, etc.)."""
    if creds is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falta el token de autenticación",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        return auth.verify_id_token(creds.credentials)
    except auth.ExpiredIdTokenError:
        detail = "El token expiró"
    except (auth.InvalidIdTokenError, auth.RevokedIdTokenError, ValueError):
        detail = "Token inválido"
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )
