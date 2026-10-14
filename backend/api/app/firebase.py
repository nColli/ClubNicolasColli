import json
import os

import firebase_admin
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth, credentials

_bearer = HTTPBearer(auto_error=False)


def init_firebase() -> None:
    if firebase_admin._apps:
        return

    cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")

    if cred_json:
        cred = credentials.Certificate(json.loads(cred_json))
    elif cred_path:
        cred = credentials.Certificate(cred_path)
    else:
        raise RuntimeError(
            "Falta FIREBASE_CREDENTIALS_JSON o FIREBASE_CREDENTIALS_PATH en el archivo .env"
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
