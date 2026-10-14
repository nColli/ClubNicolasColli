"""Reglas de horarios compartidas por los endpoints de disponibilidad y reservas."""

from datetime import date, datetime
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app import models

ZONA_HORARIA = ZoneInfo("America/Argentina/Buenos_Aires")


def ahora() -> datetime:
    return datetime.now(ZONA_HORARIA)


def es_futura(fecha: date, hora_inicio: int) -> bool:
    """Una reserva es futura si empieza después del momento actual."""
    momento = ahora()
    if fecha != momento.date():
        return fecha > momento.date()
    return hora_inicio > momento.hour


def horarios_del_dia(sede: models.Sede, fecha: date) -> list[models.HorarioSede]:
    return [h for h in sede.horarios if h.dia_semana == fecha.isoweekday()]


def dentro_del_horario(
    horarios: list[models.HorarioSede], hora_inicio: int, hora_fin: int
) -> bool:
    """La reserva tiene que entrar completa en alguna franja de apertura de la sede."""
    return any(
        h.hora_apertura <= hora_inicio and hora_fin <= h.hora_cierre for h in horarios
    )


def horas_ocupadas(db: Session, espacio_id: int, fecha: date) -> set[int]:
    """Horas del día ya tomadas por reservas del espacio."""
    r = models.Reserva
    reservas = db.execute(
        select(r.hora_inicio, r.hora_fin).where(
            r.espacio_id == espacio_id, r.fecha == fecha
        )
    )
    return {
        hora for inicio, fin in reservas for hora in range(inicio, fin)
    }
