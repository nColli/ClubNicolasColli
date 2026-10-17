import asyncio
import logging
import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI

# Antes de importar la app: database.py lee DATABASE_URL al importarse
load_dotenv()

from app.database import SessionLocal  # noqa: E402
from app.firebase import init_firebase  # noqa: E402
from app.notificaciones import enviar_avisos_pendientes  # noqa: E402
from app.routers import (  # noqa: E402
    dispositivos,
    espacios,
    notificaciones,
    reservas,
    sedes,
    usuarios,
)

log = logging.getLogger(__name__)

# Cada cuántos segundos se revisa si hay avisos para enviar: 5 minutos, salvo
# que AVISOS_INTERVALO_SEGUNDOS diga otra cosa (por ejemplo, para una demo)
_INTERVALO_AVISOS = int(os.getenv("AVISOS_INTERVALO_SEGUNDOS", "300"))


def _enviar_avisos() -> None:
    with SessionLocal() as db:
        enviar_avisos_pendientes(db)


async def _avisos_periodicos() -> None:
    """Cada `_INTERVALO_AVISOS` segundos revisa si hay avisos de reservas para enviar."""
    print(f"[avisos] Se revisan los avisos cada {_INTERVALO_AVISOS} segundos", flush=True)
    while True:
        try:
            # La consulta y el envío son bloqueantes: se corren en otro hilo
            await asyncio.to_thread(_enviar_avisos)
        except Exception:
            log.exception("Falló el envío de avisos de reservas")
        await asyncio.sleep(_INTERVALO_AVISOS)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    tarea = asyncio.create_task(_avisos_periodicos())
    yield
    tarea.cancel()


app = FastAPI(
    title="ClubNicolasColli API",
    description="API REST para la gestión de reservas de espacios deportivos.",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(usuarios.router)
app.include_router(sedes.router)
app.include_router(espacios.router)
app.include_router(reservas.router)
app.include_router(dispositivos.router)
app.include_router(notificaciones.router)


@app.get("/health", tags=["Health"], summary="Estado del servidor")
def health() -> dict:
    return {"status": "ok"}
