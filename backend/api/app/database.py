import os
from collections.abc import Iterator

from sqlalchemy import Engine, create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    pass


_engine: Engine | None = None
_SessionLocal: sessionmaker[Session] | None = None


def database_url() -> str:
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError("Falta DATABASE_URL en el archivo .env")
    # Render a veces entrega "postgres://", que SQLAlchemy no acepta
    for prefijo in ("postgres://", "postgresql://"):
        if url.startswith(prefijo):
            url = "postgresql+psycopg2://" + url.removeprefix(prefijo)
            break
    # Render exige SSL (salvo que la URL indique otro sslmode)
    if "sslmode=" not in url:
        url += "&sslmode=require" if "?" in url else "?sslmode=require"
    return url


def init_engine() -> None:
    global _engine, _SessionLocal
    if _engine is None:
        _engine = create_engine(
            database_url(), pool_size=5, max_overflow=5, pool_pre_ping=True
        )
        _SessionLocal = sessionmaker(_engine, expire_on_commit=False)


def dispose_engine() -> None:
    global _engine, _SessionLocal
    if _engine is not None:
        _engine.dispose()
        _engine = None
        _SessionLocal = None


def nueva_sesion() -> Session:
    """Sesión para usar fuera de un request (por ejemplo, en tareas periódicas).
    Usarla con `with nueva_sesion() as db:` para que se cierre."""
    if _SessionLocal is None:
        raise RuntimeError("El engine de la base no está inicializado")
    return _SessionLocal()


def get_db() -> Iterator[Session]:
    """Dependencia de FastAPI: entrega una sesión y la cierra al terminar el request.
    Los cambios se confirman con un db.commit() explícito."""
    with nueva_sesion() as session:
        yield session
