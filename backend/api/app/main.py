import asyncio
import logging
import os
from contextlib import asynccontextmanager, suppress

from dotenv import load_dotenv
from fastapi import FastAPI

load_dotenv()

from app.database import dispose_engine, init_engine, nueva_sesion  # noqa: E402
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


def _enviar_avisos() -> None:
    with nueva_sesion() as db:
        enviar_avisos_pendientes(db)


async def _avisos_periodicos(intervalo: int) -> None:
    """Revisa cada `intervalo` segundos si hay avisos de reservas para enviar."""
    while True:
        try:
            # La consulta y el envío son bloqueantes: se corren en otro hilo
            await asyncio.to_thread(_enviar_avisos)
        except Exception:
            log.exception("Falló el envío de avisos de reservas")
        await asyncio.sleep(intervalo)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    init_engine()
    # 0 desactiva la tarea (por ejemplo, si los avisos los dispara un cron externo)
    intervalo = int(os.getenv("AVISOS_INTERVALO_SEGUNDOS", "300"))
    tarea = asyncio.create_task(_avisos_periodicos(intervalo)) if intervalo > 0 else None
    yield
    if tarea is not None:
        tarea.cancel()
        with suppress(asyncio.CancelledError):
            await tarea
    dispose_engine()


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
