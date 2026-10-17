import os
from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    pass


def _database_url() -> str:
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError("Falta DATABASE_URL en el archivo .env")
    # Se indica el driver psycopg2 (el instalado): SQLAlchemy 2.1 usa psycopg 3
    # por defecto, y además Render a veces entrega "postgres://", que no acepta
    for prefijo in ("postgres://", "postgresql://"):
        if url.startswith(prefijo):
            url = "postgresql+psycopg2://" + url.removeprefix(prefijo)
    # Render exige SSL (salvo que la URL indique otro sslmode)
    if "sslmode=" not in url:
        url += "&sslmode=require" if "?" in url else "?sslmode=require"
    return url


# El engine no se conecta hasta la primera consulta
engine = create_engine(_database_url(), pool_pre_ping=True)
SessionLocal = sessionmaker(engine, expire_on_commit=False)


def get_db() -> Iterator[Session]:
    """Dependencia de FastAPI: entrega una sesión y la cierra al terminar el request.
    Los cambios se confirman con un db.commit() explícito."""
    with SessionLocal() as session:
        yield session
