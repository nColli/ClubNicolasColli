"""Notificaciones de reservas.

Hay dos tipos:
- La campana de la app: filas de la tabla NOTIFICACION (`registrar`). Se crean
  al confirmar o cancelar una reserva y con cada aviso.
- Los avisos push 24 h y 1 h antes de cada reserva (`enviar_avisos_pendientes`),
  que se mandan por Firebase Cloud Messaging a los celulares del usuario. Los
  revisa una tarea de la API, cada 5 minutos por defecto (ver main.py).
"""

import logging
from datetime import datetime, time, timedelta

from firebase_admin import exceptions, messaging
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app import horarios, models

log = logging.getLogger(__name__)

_DIAS = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]
_MESES = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


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


def describir_reserva(reserva: models.Reserva) -> str:
    """ "Fútbol 1 · Sede Ramos Mejía\nmié, 15 oct · 18:00 – 20:00 hs" """
    espacio, fecha = reserva.espacio, reserva.fecha
    return (
        f"{espacio.tipo} {espacio.numero} · Sede {espacio.sede.nombre}\n"
        f"{_DIAS[fecha.weekday()]}, {fecha.day} {_MESES[fecha.month - 1]} · "
        f"{reserva.hora_inicio:02d}:00 – {reserva.hora_fin:02d}:00 hs"
    )


def enviar_avisos_pendientes(db: Session) -> None:
    """Envía los avisos que correspondan en este momento.

    El de 24 h se envía en cuanto faltan 24 horas o menos para el inicio,
    así también lo recibe una reserva hecha con menos anticipación (o si la
    API estuvo apagada). Si ya falta 1 hora o menos solo se envía el de 1 h,
    que se envía en la última hora.
    """
    ahora = horarios.ahora()
    r = models.Reserva
    reservas = db.scalars(
        select(r).where(
            r.fecha.between(ahora.date(), ahora.date() + timedelta(days=2)),
            or_(r.aviso_24h_enviado.is_(False), r.aviso_1h_enviado.is_(False)),
        )
    ).all()
    print(
        f"[avisos] {ahora:%d/%m %H:%M}: {len(reservas)} reserva(s) con avisos pendientes",
        flush=True,
    )

    for reserva in reservas:
        inicio = datetime.combine(
            reserva.fecha, time(reserva.hora_inicio), horarios.ZONA_HORARIA
        )
        falta = inicio - ahora
        if not reserva.aviso_24h_enviado and timedelta(hours=1) < falta <= timedelta(hours=24):
            reserva.aviso_24h_enviado = True
            # Con menos de 24 h de anticipación la reserva puede ser hoy mismo
            _avisar(
                db,
                reserva,
                "Tu reserva es hoy" if reserva.fecha == ahora.date() else "Tu reserva es mañana",
            )
        elif not reserva.aviso_1h_enviado and timedelta(0) < falta <= timedelta(hours=1):
            reserva.aviso_1h_enviado = True
            minutos = round(falta.total_seconds() / 60)
            _avisar(
                db,
                reserva,
                "Tu reserva empieza en 1 hora"
                if minutos >= 55
                else f"Tu reserva empieza en {max(minutos, 1)} minutos",
            )


def _avisar(db: Session, reserva: models.Reserva, titulo: str) -> None:
    """Guarda el aviso en la campana y lo manda por push a los celulares del usuario."""
    cuerpo = describir_reserva(reserva)
    registrar(db, reserva.usuario_id, reserva.id, titulo, cuerpo)
    # Se confirma antes de enviar: así el aviso queda marcado como enviado
    # (y en la campana) aunque falle el push, y no se repite
    db.commit()

    tokens = db.scalars(
        select(models.Dispositivo.token).where(
            models.Dispositivo.usuario_id == reserva.usuario_id
        )
    ).all()
    print(
        f'[push] Enviando "{titulo}" (reserva {reserva.id}) a {len(tokens)} '
        f"dispositivo(s) del usuario {reserva.usuario_id}",
        flush=True,
    )
    if not tokens:
        print("[push] El usuario no tiene dispositivos: el aviso queda solo en la campana", flush=True)
        return

    mensajes = [
        messaging.Message(
            token=token,
            notification=messaging.Notification(title=titulo, body=cuerpo),
            # La app usa reserva_id para abrir el detalle al tocar la notificación
            data={"reserva_id": str(reserva.id)},
            android=messaging.AndroidConfig(priority="high"),
        )
        for token in tokens
    ]
    try:
        respuesta = messaging.send_each(mensajes)
    except exceptions.FirebaseError:
        log.exception("No se pudo enviar el aviso de la reserva %s", reserva.id)
        return

    for token, r in zip(tokens, respuesta.responses):
        if r.success:
            print(f"[push]   OK    {token[:12]}... ({r.message_id})", flush=True)
        else:
            print(
                f"[push]   ERROR {token[:12]}... {type(r.exception).__name__}: {r.exception}",
                flush=True,
            )

    # Los tokens que FCM ya no reconoce (la app se desinstaló o se cerró
    # sesión) se borran
    invalidos = [
        token
        for token, r in zip(tokens, respuesta.responses)
        if isinstance(r.exception, (messaging.UnregisteredError, messaging.SenderIdMismatchError))
    ]
    if invalidos:
        db.query(models.Dispositivo).filter(models.Dispositivo.token.in_(invalidos)).delete()
        db.commit()
        print(f"[push] Se borraron {len(invalidos)} token(s) inválido(s)", flush=True)
