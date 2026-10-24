# ClubNicolasColli — API REST

API en **FastAPI** + **PostgreSQL** (acceso a datos con **SQLAlchemy 2**). La autenticación la hace **Firebase Auth**: la app Flutter manda el ID token de Firebase y la API lo verifica.

## Instalación, configuración y despliegue

Los pasos para configurar Firebase, crear la base en Render, instalar dependencias, completar el `.env`, ejecutar `run_schema.py`, correr la API en local y desplegarla en Render están en [../README.md](../README.md).

Con la API corriendo, la documentación interactiva queda en `/docs` (Swagger UI) y la especificación en `/openapi.json`.

## Notificaciones push

La API envía por Firebase Cloud Messaging un aviso **24 horas** y otro **1 hora** antes del inicio de cada reserva, a todos los dispositivos del usuario. El aviso incluye sede, espacio, fecha y horario, y en `data` el `reserva_id` para que la app abra el detalle al tocarlo.

- Una tarea dentro de la API revisa cada 5 minutos (configurable con `AVISOS_INTERVALO_SEGUNDOS` en el `.env`) qué reservas entraron en la ventana de un aviso. El de 24 h se envía en cuanto faltan 24 h o menos para el inicio, así que una reserva hecha con menos anticipación (o una que la API no llegó a revisar por estar suspendida) lo recibe en la siguiente revisión, con el título "Tu reserva es hoy" o "Tu reserva es mañana" según el día. Si ya falta 1 h o menos, solo se envía el de 1 h, que se envía en la última hora.
- Cada aviso se marca como enviado en `RESERVA` (`aviso_24h_enviado`, `aviso_1h_enviado`) antes de mandar el push, así no se repite.
- La campana del inicio (`GET /notificaciones`) no se guarda en la base: muestra las reservas que todavía no empezaron y ya tienen un aviso enviado, con el título y el cuerpo armados en el momento.
- La app registra el token de FCM con `POST /dispositivos` cada vez que se abre con sesión iniciada. Al cerrar sesión borra el token en el celular; los tokens que FCM informa como inválidos se borran de la base en el siguiente envío.

## Autenticación

Todos los endpoints de usuarios y reservas requieren el header:

```
Authorization: Bearer <ID token de Firebase>
```

En Flutter el token se obtiene con `await FirebaseAuth.instance.currentUser!.getIdToken()`.

## Endpoints

### `POST /usuarios` — Registrar usuario

Se llama justo después de `createUserWithEmailAndPassword`. El `uid` y el `email` se toman del token.

```json
{
  "nombre": "Juana",
  "apellido": "González",
  "dni": "40123456",
  "fecha_nacimiento": "2000-05-21"
}
```

| Código | Significado |
|---|---|
| 201 | Usuario creado; devuelve el usuario |
| 401 | Falta el token, o es inválido o expiró |
| 409 | Usuario ya registrado, o ya hay otro usuario con ese DNI |
| 422 | Datos inválidos (campos vacíos, DNI que no tiene 7 u 8 dígitos, fecha futura) |

### `GET /usuarios/me` — Perfil del usuario autenticado

| Código | Significado |
|---|---|
| 200 | Devuelve el usuario |
| 401 | Falta el token, o es inválido o expiró |
| 404 | El usuario no está registrado en la base |

### `PUT /usuarios/me` — Editar el perfil

Actualiza nombre, apellido, DNI y fecha de nacimiento del usuario autenticado. El email no se puede modificar (es el de la cuenta de Firebase).

```json
{ "nombre": "Juana", "apellido": "González", "dni": "40123456", "fecha_nacimiento": "2000-05-21" }
```

| Código | Significado |
|---|---|
| 200 | Perfil actualizado; devuelve el usuario |
| 401 | Falta el token, o es inválido o expiró |
| 404 | El usuario no está registrado en la base |
| 409 | Ya hay otro usuario con ese DNI |
| 422 | Datos inválidos (campos vacíos, DNI que no tiene 7 u 8 dígitos, fecha futura) |

### `DELETE /usuarios/me` — Dar de baja la cuenta

Elimina al usuario de la base junto con sus reservas (pasadas y futuras, así los horarios quedan libres) y sus dispositivos, y borra su cuenta de Firebase. No se puede deshacer.

| Código | Significado |
|---|---|
| 204 | Cuenta eliminada |
| 401 | Falta el token, o es inválido o expiró |
| 404 | El usuario no está registrado en la base |
| 502 | No se pudo eliminar la cuenta de Firebase; la base no se modifica |

### `GET /reservas` — Reservas del usuario autenticado

Query params opcionales:

- `proximas=true`: solo las reservas que todavía no terminaron, de la más cercana a la más lejana. Sin este parámetro devuelve todo el historial, de la más reciente a la más antigua.
- `limit`: cantidad máxima de reservas (1 a 100).

Cada reserva incluye su espacio deportivo, la sede y el `precio_total` (`precio_hora` × horas). Si el usuario no tiene reservas devuelve `[]`.

```json
[
  {
    "id": 1,
    "fecha": "2026-10-09",
    "hora_inicio": 19,
    "hora_fin": 20,
    "precio_total": "2500.00",
    "espacio_id": 2,
    "espacio_nombre": "Moron_Rivadavia_17500_Tenis_2",
    "espacio_tipo": "Tenis",
    "espacio_numero": 2,
    "sede_id": 1,
    "sede_nombre": "Morón",
    "sede_direccion": "Av. Rivadavia 17500",
    "sede_imagen_url": "https://..."
  }
]
```

### `POST /reservas` — Reservar un espacio

Reserva un espacio para el usuario autenticado. Las horas son completas (`hora_inicio` de 0 a 23, `hora_fin` de 1 a 24) y la duración mínima es una hora.

```json
{ "espacio_id": 4, "fecha": "2026-10-15", "hora_inicio": 18, "hora_fin": 20 }
```

| Código | Significado |
|---|---|
| 201 | Reserva creada; devuelve la reserva con el mismo formato que `GET /reservas` |
| 401 | Falta el token, o es inválido o expiró |
| 404 | El espacio no existe o el usuario no está registrado |
| 409 | El espacio ya está reservado en un horario superpuesto |
| 422 | El horario ya pasó, está fuera del horario de la sede ese día, o la hora de fin no es posterior a la de inicio |

La superposición se valida antes de insertar y, además, la constraint `reserva_sin_superposicion` de la base la impide aunque dos usuarios reserven al mismo tiempo.

### `GET /reservas/{reserva_id}` — Detalle de una reserva

Devuelve una reserva del usuario autenticado, con el mismo formato que `GET /reservas`. La app lo usa para abrir el detalle desde una notificación. Si la reserva no existe o es de otro usuario devuelve 404.

### `DELETE /reservas/{reserva_id}` — Cancelar una reserva

Cancela una reserva del usuario autenticado que todavía no empezó. La reserva se elimina, así que el espacio vuelve a quedar disponible en ese horario.

| Código | Significado |
|---|---|
| 204 | Reserva cancelada |
| 401 | Falta el token, o es inválido o expiró |
| 404 | La reserva no existe o es de otro usuario |
| 409 | La reserva ya empezó o terminó |

### `GET /sedes` — Listar sedes

No requiere autenticación. Devuelve cada sede con los tipos de espacios deportivos que ofrece y sus horarios de funcionamiento (`dia_semana`: 1 = lunes, 7 = domingo).

```json
[
  {
    "id": 1,
    "nombre": "Morón",
    "direccion": "Av. Rivadavia 17500",
    "imagen_url": "https://...",
    "deportes": ["Fútbol", "Tenis"],
    "horarios": [{ "dia_semana": 1, "hora_apertura": 8, "hora_cierre": 23 }]
  }
]
```

### `GET /sedes/{sede_id}/espacios` — Espacios de una sede

No requiere autenticación. Devuelve los espacios deportivos de la sede, ordenados por tipo y número. Si la sede no existe devuelve 404.

```json
[
  {
    "id": 4,
    "tipo": "Fútbol",
    "numero": 1,
    "nombre": "RamosMejia_Belgrano_1240_Futbol_1",
    "precio_hora": "3200.00"
  }
]
```

### `GET /espacios/{espacio_id}/disponibilidad?fecha=AAAA-MM-DD` — Disponibilidad de un espacio

No requiere autenticación. Devuelve cada hora en que la sede está abierta ese día y si se puede reservar: una hora no está disponible si ya está reservada o si ya pasó (hora de Argentina). Si la sede no abre ese día, `horas` es `[]`. Si el espacio no existe devuelve 404.

```json
{
  "espacio_id": 4,
  "fecha": "2026-10-15",
  "horas": [
    { "hora": 8, "disponible": true },
    { "hora": 9, "disponible": false }
  ]
}
```

### `POST /dispositivos` — Registrar un dispositivo para notificaciones

Guarda el token de FCM del celular del usuario autenticado. La app lo llama en cada inicio: si el token ya estaba registrado no se duplica, y si era de otro usuario (en el mismo celular) pasa a ser del usuario autenticado. Responde 204; 404 si el usuario no está registrado.

```json
{ "token": "<token de FCM>" }
```

### `GET /notificaciones` — Notificaciones del usuario

Devuelve los recordatorios de las reservas del usuario autenticado que todavía no empezaron y ya tienen un aviso enviado (24 h o 1 h antes), de la más cercana a la más lejana. No se guardan en la base: el título se calcula en el momento ("Tu reserva es mañana", "Tu reserva es hoy" o "Tu reserva empieza en 40 minutos").

```json
[
  {
    "reserva_id": 7,
    "titulo": "Tu reserva es mañana",
    "cuerpo": "Fútbol 1 · Sede Ramos Mejía\nlun, 12 oct · 10:00 – 12:00 hs"
  }
]
```
