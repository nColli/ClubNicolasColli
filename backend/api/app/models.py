"""Modelos ORM. Solo mapean las tablas para consultarlas desde la API: la fuente
de verdad del schema es database/schema.sql. Si se cambia una tabla ahí, hay que
actualizar el modelo correspondiente."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Numeric,
    SmallInteger,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Usuario(Base):
    __tablename__ = "usuario"

    uid: Mapped[str] = mapped_column(String(255), primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True)
    nombre: Mapped[str] = mapped_column(String(255))
    apellido: Mapped[str] = mapped_column(String(255))
    # Opcional solo para los usuarios creados antes de que se pidiera el DNI
    # (ver database/migracion_002_dni_usuario.sql)
    dni: Mapped[str | None] = mapped_column(String(8), unique=True)
    fecha_nacimiento: Mapped[date] = mapped_column(Date)

    reservas: Mapped[list["Reserva"]] = relationship(back_populates="usuario")
    dispositivos: Mapped[list["Dispositivo"]] = relationship(
        back_populates="usuario", passive_deletes=True
    )


class Sede(Base):
    __tablename__ = "sede"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(100))
    direccion: Mapped[str] = mapped_column(String(200))
    imagen_url: Mapped[str | None] = mapped_column(String(500))

    horarios: Mapped[list["HorarioSede"]] = relationship(
        back_populates="sede",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="(HorarioSede.dia_semana, HorarioSede.hora_apertura)",
    )
    espacios: Mapped[list["EspacioDeportivo"]] = relationship(back_populates="sede")


class HorarioSede(Base):
    __tablename__ = "horario_sede"

    id: Mapped[int] = mapped_column(primary_key=True)
    sede_id: Mapped[int] = mapped_column(ForeignKey("sede.id", ondelete="CASCADE"))
    dia_semana: Mapped[int] = mapped_column(SmallInteger)  # 1 = lunes, 7 = domingo
    hora_apertura: Mapped[int] = mapped_column(SmallInteger)  # 0 a 23
    hora_cierre: Mapped[int] = mapped_column(SmallInteger)  # 1 a 24

    sede: Mapped[Sede] = relationship(back_populates="horarios")


class EspacioDeportivo(Base):
    __tablename__ = "espacio_deportivo"
    __table_args__ = (UniqueConstraint("sede_id", "numero"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    sede_id: Mapped[int] = mapped_column(ForeignKey("sede.id"))
    tipo: Mapped[str] = mapped_column(String(50))  # Fútbol, Tenis, Paddle, etc.
    numero: Mapped[int] = mapped_column(SmallInteger)
    nombre: Mapped[str] = mapped_column(String(100))
    precio_hora: Mapped[Decimal] = mapped_column(Numeric(10, 2))

    sede: Mapped[Sede] = relationship(back_populates="espacios")
    reservas: Mapped[list["Reserva"]] = relationship(back_populates="espacio")


class Reserva(Base):
    __tablename__ = "reserva"
    # La constraint reserva_sin_superposicion (schema.sql) impide dos reservas
    # superpuestas del mismo espacio en la misma fecha.

    id: Mapped[int] = mapped_column(primary_key=True)
    espacio_id: Mapped[int] = mapped_column(ForeignKey("espacio_deportivo.id"))
    usuario_id: Mapped[str] = mapped_column(ForeignKey("usuario.uid"))
    fecha: Mapped[date] = mapped_column(Date)
    hora_inicio: Mapped[int] = mapped_column(SmallInteger)
    hora_fin: Mapped[int] = mapped_column(SmallInteger)
    aviso_24h_enviado: Mapped[bool] = mapped_column(Boolean, default=False)
    aviso_1h_enviado: Mapped[bool] = mapped_column(Boolean, default=False)

    espacio: Mapped[EspacioDeportivo] = relationship(back_populates="reservas")
    usuario: Mapped[Usuario] = relationship(back_populates="reservas")


class Dispositivo(Base):
    """Instalación de la app donde el usuario recibe notificaciones push."""

    __tablename__ = "dispositivo"

    token: Mapped[str] = mapped_column(String(512), primary_key=True)  # token de FCM
    usuario_id: Mapped[str] = mapped_column(
        ForeignKey("usuario.uid", ondelete="CASCADE")
    )
    actualizado: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    usuario: Mapped[Usuario] = relationship(back_populates="dispositivos")


class Notificacion(Base):
    """Notificación que el usuario ve en la app (campana del inicio)."""

    __tablename__ = "notificacion"

    id: Mapped[int] = mapped_column(primary_key=True)
    usuario_id: Mapped[str] = mapped_column(
        ForeignKey("usuario.uid", ondelete="CASCADE")
    )
    # NULL si la reserva se canceló (o la notificación no es de una reserva)
    reserva_id: Mapped[int | None] = mapped_column(
        ForeignKey("reserva.id", ondelete="SET NULL")
    )
    titulo: Mapped[str] = mapped_column(String(200))
    cuerpo: Mapped[str] = mapped_column(String(500))
    creada: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    leida: Mapped[bool] = mapped_column(Boolean, default=False)
