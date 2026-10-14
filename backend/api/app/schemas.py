from datetime import date, datetime
from decimal import Decimal

from pydantic import (
    BaseModel,
    ConfigDict,
    EmailStr,
    Field,
    field_validator,
    model_validator,
)


class DatosPersonales(BaseModel):
    """Datos del perfil que el usuario carga al registrarse y puede editar."""

    nombre: str = Field(min_length=1, max_length=255)
    apellido: str = Field(min_length=1, max_length=255)
    dni: str = Field(pattern=r"^\d{7,8}$", description="7 u 8 dígitos, sin puntos")
    fecha_nacimiento: date

    @field_validator("dni", mode="before")
    @classmethod
    def dni_sin_espacios(cls, v: object) -> object:
        return v.strip() if isinstance(v, str) else v

    @field_validator("nombre", "apellido")
    @classmethod
    def no_vacio(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("no puede estar vacío")
        return v

    @field_validator("fecha_nacimiento")
    @classmethod
    def no_futura(cls, v: date) -> date:
        if v >= date.today():
            raise ValueError("debe ser una fecha pasada")
        return v


class UsuarioCreate(DatosPersonales):
    uid: str = Field(min_length=1, max_length=255, description="UID de Firebase")
    email: EmailStr

    model_config = {
        "json_schema_extra": {
            "example": {
                "uid": "Xb3kP9...firebaseUid",
                "email": "juana@example.com",
                "nombre": "Juana",
                "apellido": "González",
                "dni": "40123456",
                "fecha_nacimiento": "2000-05-21",
            }
        }
    }


class UsuarioUpdate(DatosPersonales):
    """El email no se puede editar: es el de la cuenta de Firebase."""

    model_config = {
        "json_schema_extra": {
            "example": {
                "nombre": "Juana",
                "apellido": "González",
                "dni": "40123456",
                "fecha_nacimiento": "2000-05-21",
            }
        }
    }


class Usuario(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    uid: str
    email: EmailStr
    nombre: str
    apellido: str
    dni: str | None = Field(
        description="null solo en usuarios registrados antes de que se pidiera el DNI"
    )
    fecha_nacimiento: date


class HorarioSede(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    dia_semana: int = Field(description="1 = lunes, 7 = domingo")
    hora_apertura: int
    hora_cierre: int


class Sede(BaseModel):
    id: int
    nombre: str
    direccion: str
    imagen_url: str | None
    deportes: list[str] = Field(description="Tipos de espacios deportivos que tiene la sede")
    horarios: list[HorarioSede]


class EspacioDeportivo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tipo: str = Field(description="Fútbol, Tenis, Paddle, etc.")
    numero: int = Field(description="Número del espacio dentro de la sede")
    nombre: str
    precio_hora: Decimal


class HoraDisponibilidad(BaseModel):
    hora: int = Field(description="Hora de inicio del turno de una hora (0 a 23)")
    disponible: bool = Field(
        description="false si ya está reservada o si el horario ya pasó"
    )


class Disponibilidad(BaseModel):
    espacio_id: int
    fecha: date
    horas: list[HoraDisponibilidad] = Field(
        description=(
            "Una entrada por cada hora en que la sede está abierta ese día, en orden. "
            "Lista vacía si la sede no abre ese día."
        )
    )


class ReservaCreate(BaseModel):
    espacio_id: int
    fecha: date
    hora_inicio: int = Field(ge=0, le=23, description="Hora completa de inicio (0 a 23)")
    hora_fin: int = Field(ge=1, le=24, description="Hora completa de fin (1 a 24)")

    @model_validator(mode="after")
    def fin_posterior_al_inicio(self) -> "ReservaCreate":
        if self.hora_fin <= self.hora_inicio:
            raise ValueError("la hora de fin debe ser posterior a la de inicio")
        return self

    model_config = {
        "json_schema_extra": {
            "example": {"espacio_id": 4, "fecha": "2026-10-15", "hora_inicio": 18, "hora_fin": 20}
        }
    }


class Reserva(BaseModel):
    id: int
    fecha: date
    hora_inicio: int
    hora_fin: int
    precio_total: Decimal
    espacio_id: int
    espacio_nombre: str
    espacio_tipo: str
    espacio_numero: int
    sede_id: int
    sede_nombre: str
    sede_direccion: str
    sede_imagen_url: str | None


class Notificacion(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reserva_id: int | None = Field(
        description="Reserva a la que se refiere; null si se canceló"
    )
    titulo: str
    cuerpo: str
    creada: datetime
    leida: bool


class DispositivoCreate(BaseModel):
    token: str = Field(min_length=1, max_length=512, description="Token de FCM del dispositivo")


class ResultadoAvisos(BaseModel):
    enviados: int = Field(description="Avisos de reserva enviados en esta ejecución")


class ErrorResponse(BaseModel):
    detail: str
