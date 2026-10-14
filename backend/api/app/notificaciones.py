"""Avisos push de reservas próximas: 24 horas y 1 hora antes del inicio.

`enviar_avisos_pendientes` revisa qué reservas entraron en la ventana de algún
aviso y todavía no lo recibieron, y lo envía por Firebase Cloud Messaging a
todos los dispositivos del usuario. La ejecutan una tarea periódica de la API
(ver main.py) y el endpoint POST /notificaciones/enviar-pendientes.
"""

import logging
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta

from firebase_admin import exceptions, messaging
from sqlalchemy import or_, select, update
from sqlalchemy.orm import Session

from app import horarios, models

log = logging.getLogger(__name__)

_DIAS = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]
_MESES = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


@dataclass(frozen=True)
class _Aviso:
    tipo: str  # se manda en el campo "tipo" de la notificación
    columna: str  # columna de RESERVA que marca si ya se envió
    desde: timedelta  # el aviso se envía a partir de este tiempo antes del inicio
    hasta: timedelta  # ...y hasta este tiempo antes del inicio


# Si la API estuvo apagada y se pasó la ventana de un aviso, ese aviso ya no se
# envía (un "es mañana" que llega 3 horas antes confundiría). Una reserva hecha
# con menos de 24 h de anticipación solo recibe el aviso de 1 h.
AVISOS = (
    _Aviso("aviso_24h", "aviso_24h_enviado", timedelta(hours=24), timedelta(hours=23)),
    _Aviso("aviso_1h", "aviso_1h_enviado", timedelta(hours=1), timedelta(0)),
)


@dataclass(frozen=True)
class _DatosReserva:
    id: int
    usuario_id: str
    inicio: datetime
    hora_inicio: int
    hora_fin: int
    espacio: str
    sede: str


def enviar_avisos_pendientes(db: Session) -> int:
    """Envía los avisos que correspondan en este momento. Devuelve cuántos envió."""
    ahora = horarios.ahora()
    enviados = 0
    for reserva in _reservas_candidatas(db, ahora):
        for aviso in AVISOS:
            if not (reserva.inicio - aviso.desde <= ahora < reserva.inicio - aviso.hasta):
                continue
            if not _reclamar(db, reserva.id, aviso):
                continue  # otra ejecución ya lo envió
            _enviar(db, reserva, aviso, ahora)
            enviados += 1
    return enviados


def _reservas_candidatas(db: Session, ahora: datetime) -> list[_DatosReserva]:
    """Reservas de hoy a pasado mañana a las que les falta algún aviso."""
    r, e, s = models.Reserva, models.EspacioDeportivo, models.Sede
    filas = db.execute(
        select(
            r.id, r.usuario_id, r.fecha, r.hora_inicio, r.hora_fin,
            e.tipo, e.numero, s.nombre,
        )
        .join(e, e.id == r.espacio_id)
        .join(s, s.id == e.sede_id)
        .where(
            r.fecha.between(ahora.date(), ahora.date() + timedelta(days=2)),
            or_(r.aviso_24h_enviado.is_(False), r.aviso_1h_enviado.is_(False)),
        )
    )
    return [
        _DatosReserva(
            id=f.id,
            usuario_id=f.usuario_id,
            inicio=datetime.combine(f.fecha, time(f.hora_inicio), horarios.ZONA_HORARIA),
            hora_inicio=f.hora_inicio,
            hora_fin=f.hora_fin,
            espacio=f"{f.tipo} {f.numero}",
            sede=f.nombre,
        )
        for f in filas
    ]


def _reclamar(db: Session, reserva_id: int, aviso: _Aviso) -> bool:
    """Marca el aviso como enviado antes de enviarlo. Si dos ejecuciones corren
    a la vez, solo una logra marcarlo, así el usuario no lo recibe dos veces."""
    columna = getattr(models.Reserva, aviso.columna)
    resultado = db.execute(
        update(models.Reserva)
        .where(models.Reserva.id == reserva_id, columna.is_(False))
        .values({columna: True})
    )
    db.commit()
    return resultado.rowcount == 1


def describir_reserva(
    espacio: str, sede: str, fecha: date, hora_inicio: int, hora_fin: int
) -> str:
    """ "Fútbol 1 · Sede Ramos Mejía\nmié, 15 oct · 18:00 – 20:00 hs" """
    return (
        f"{espacio} · Sede {sede}\n"
        f"{_DIAS[fecha.weekday()]}, {fecha.day} {_MESES[fecha.month - 1]} · "
        f"{hora_inicio:02d}:00 – {hora_fin:02d}:00 hs"
    )


def registrar(
    db: Session, usuario_id: str, reserva_id: int | None, titulo: str, cuerpo: str
) -> None:
    """Guarda una notificación para la campana de la app. No hace commit: se
    confirma junto con el cambio que la origina."""
    db.add(
        models.Notificacion(
            usuario_id=usuario_id, reserva_id=reserva_id, titulo=titulo, cuerpo=cuerpo
        )
    )


def _texto(reserva: _DatosReserva, aviso: _Aviso, ahora: datetime) -> tuple[str, str]:
    if aviso.tipo == "aviso_24h":
        titulo = "Tu reserva es mañana"
    else:
        minutos = round((reserva.inicio - ahora).total_seconds() / 60)
        titulo = (
            "Tu reserva empieza en 1 hora"
            if minutos >= 55
            else f"Tu reserva empieza en {max(minutos, 1)} minutos"
        )
    cuerpo = describir_reserva(
        reserva.espacio,
        reserva.sede,
        reserva.inicio.date(),
        reserva.hora_inicio,
        reserva.hora_fin,
    )
    return titulo, cuerpo


def _enviar(db: Session, reserva: _DatosReserva, aviso: _Aviso, ahora: datetime) -> None:
    titulo, cuerpo = _texto(reserva, aviso, ahora)
    # Queda en la campana de la app aunque el usuario no tenga dispositivos
    registrar(db, reserva.usuario_id, reserva.id, titulo, cuerpo)
    db.commit()

    tokens = db.scalars(
        select(models.Dispositivo.token).where(
            models.Dispositivo.usuario_id == reserva.usuario_id
        )
    ).all()
    if not tokens:
        return

    mensajes = [
        messaging.Message(
            token=token,
            notification=messaging.Notification(title=titulo, body=cuerpo),
            # La app usa reserva_id para abrir el detalle al tocar la notificación
            data={"reserva_id": str(reserva.id), "tipo": aviso.tipo},
            android=messaging.AndroidConfig(priority="high"),
        )
        for token in tokens
    ]
    try:
        respuesta = messaging.send_each(mensajes)
    except exceptions.FirebaseError:
        log.exception("No se pudo enviar el %s de la reserva %s", aviso.tipo, reserva.id)
        return

    # Los tokens que FCM ya no reconoce (app desinstalada, etc.) se borran
    invalidos = [
        token
        for token, r in zip(tokens, respuesta.responses)
        if not r.success
        and isinstance(r.exception, (messaging.UnregisteredError, messaging.SenderIdMismatchError))
    ]
    if invalidos:
        db.query(models.Dispositivo).filter(models.Dispositivo.token.in_(invalidos)).delete()
        db.commit()
    log.info(
        "%s de la reserva %s: %s de %s dispositivos",
        aviso.tipo, reserva.id, respuesta.success_count, len(tokens),
    )
