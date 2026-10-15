# ClubNicolasColli — API REST

API en **FastAPI** + **PostgreSQL** (acceso a datos con **SQLAlchemy 2**). La autenticación la hace **Firebase Auth**: la app Flutter manda el ID token de Firebase y la API lo verifica.

## Requisitos

- Python 3.12+
- Una base PostgreSQL (local o en Render)
- Un proyecto de Firebase con una **cuenta de servicio**: Firebase Console → Configuración del proyecto → Cuentas de servicio → *Generar nueva clave privada*

## Configuración

```bash
cd backend/api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # y completar los valores
```

Variables de `.env`:

| Variable | Descripción |
|---|---|
| `DATABASE_URL` | URL de conexión a PostgreSQL (si falta `sslmode`, se agrega `sslmode=require`) |
| `FIREBASE_CREDENTIALS_PATH` | Ruta al JSON de la cuenta de servicio (para usar en local) |
| `FIREBASE_CREDENTIALS_JSON` | Contenido del JSON en una línea (para usar en Render, en lugar del path) |
| `AVISOS_INTERVALO_SEGUNDOS` | Cada cuántos segundos la API revisa si hay avisos de reservas para enviar (por defecto `300`; `0` lo desactiva) |
| `CRON_SECRET` | Secreto para `POST /notificaciones/enviar-pendientes` (opcional; sin él, el endpoint responde 403) |

## Base de datos

La fuente de verdad del schema es [`../database/schema.sql`](../database/schema.sql). Los modelos de `app/models.py` solo mapean esas tablas para consultarlas desde la API; la API no crea ni modifica tablas.

Los scripts SQL se ejecutan con `run_schema.py` (usa el `DATABASE_URL` del `.env` de `backend/database`):

```bash
cd backend/database
python run_schema.py              # ejecuta schema.sql (¡borra y recrea las tablas!)
python run_schema.py seed.sql     # carga sedes, horarios y espacios de prueba (no usar en producción)
```

Si la base se creó antes de alguno de estos cambios, ejecutar las migraciones que falten, en orden:

```bash
python run_schema.py migracion_002_dni_usuario.sql
python run_schema.py migracion_003_notificaciones.sql
python run_schema.py migracion_004_notificaciones_app.sql
```

Para cambiar el schema:

1. Modificar `schema.sql`.
2. Si hay una base con datos que no se quiere recrear, escribir un script de migración (`migracion_NNN_descripcion.sql`, ver `migracion_002_dni_usuario.sql`) y ejecutarlo con `python run_schema.py migracion_NNN_descripcion.sql`.
3. Actualizar el modelo correspondiente en `app/models.py`.

## Ejecutar

```bash
fastapi dev app/main.py        # desarrollo, con recarga automática
```

- Swagger UI: http://localhost:8000/docs
- OpenAPI JSON: http://localhost:8000/openapi.json

## Despliegue en Render

- **Build command:** `pip install -r requirements.txt`
- **Start command:** `fastapi run app/main.py --port $PORT`
- **Root directory:** `backend/api`
- Variables de entorno: `DATABASE_URL` (Internal Database URL de Render), `FIREBASE_CREDENTIALS_JSON` y `CRON_SECRET`
- En el plan free, Render suspende el servicio después de 15 minutos sin tráfico, y mientras está suspendido no se envían avisos. Para que lleguen siempre, configurar un cron externo gratuito (por ejemplo [cron-job.org](https://cron-job.org)) que cada 5 minutos haga `POST https://<tu-api>.onrender.com/notificaciones/enviar-pendientes` con el header `X-Cron-Secret: <CRON_SECRET>`.

## Notificaciones push

La API envía por Firebase Cloud Messaging un aviso **24 horas** y otro **1 hora** antes del inicio de cada reserva, a todos los dispositivos del usuario. El aviso incluye sede, espacio, fecha y horario, y en `data` el `reserva_id` para que la app abra el detalle al tocarlo.

- Una tarea dentro de la API revisa cada `AVISOS_INTERVALO_SEGUNDOS` qué reservas entraron en la ventana de un aviso. El de 24 h se envía entre 24 h y 23 h antes del inicio; el de 1 h, en la última hora. Si la API estuvo suspendida y se pasó la ventana, ese aviso se saltea; una reserva hecha con menos de 24 h de anticipación solo recibe el de 1 h.
- Cada aviso se marca como enviado en `RESERVA` (`aviso_24h_enviado`, `aviso_1h_enviado`) antes de enviarlo, así no se repite aunque la tarea y el cron corran a la vez.
- Además del push, cada aviso queda guardado en `NOTIFICACION` junto con las reservas confirmadas y canceladas; la app las muestra en la campana del inicio (`GET /notificaciones`).
- La app registra el token de FCM con `POST /dispositivos` al iniciar sesión y lo quita con `DELETE /dispositivos` al cerrarla. Los tokens que FCM informa como inválidos se borran.

## Autenticación

Todos los endpoints de usuarios y reservas requieren el header:

```
Authorization: Bearer <ID token de Firebase>
```

En Flutter el token se obtiene con `await FirebaseAuth.instance.currentUser!.getIdToken()`.

## Endpoints

### `POST /usuarios` — Registrar usuario

Se llama justo después de `createUserWithEmailAndPassword`. El `uid` y el `email` del body tienen que coincidir con los del token.

```json
{
  "uid": "Xb3kP9...",
  "email": "juana@example.com",
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
| 403 | El uid o el email no coinciden con el token |
| 409 | Usuario ya registrado, o ya hay otro usuario con ese DNI |
| 422 | Datos inválidos (campos vacíos, DNI que no tiene 7 u 8 dígitos, fecha futura, email mal formado) |

### `GET /usuarios/me` — Perfil del usuario autenticado

| Código | Significado |
|---|---|
| 200 | Devuelve el usuario |
| 401 | Falta el token, o es inválido o expiró |
| 404 | El usuario no está registrado en la base |

`dni` puede venir en `null` solo para usuarios registrados antes de que se pidiera el DNI; lo cargan editando el perfil.

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

Elimina al usuario de la base junto con sus reservas (pasadas y futuras, así los horarios quedan libres), sus dispositivos y sus notificaciones, y borra su cuenta de Firebase. No se puede deshacer.

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

Guarda el token de FCM del dispositivo del usuario autenticado. Si el token ya estaba registrado (por ejemplo, por otro usuario en el mismo celular), pasa a ser del usuario autenticado. Responde 204; 404 si el usuario no está registrado.

```json
{ "token": "<token de FCM>" }
```

### `DELETE /dispositivos?token=<token de FCM>` — Quitar un dispositivo

Deja de enviar notificaciones a ese dispositivo (la app lo llama al cerrar sesión). Responde 204.

### `GET /notificaciones` — Notificaciones del usuario

Devuelve las notificaciones del usuario autenticado (reservas confirmadas y canceladas, y recordatorios de 24 h y 1 h), de la más nueva a la más vieja. Query param opcional `limit` (1 a 100, por defecto 30). `reserva_id` es `null` si la reserva se canceló.

```json
[
  {
    "id": 12,
    "reserva_id": 7,
    "titulo": "Reserva confirmada",
    "cuerpo": "Fútbol 1 · Sede Ramos Mejía\nlun, 12 oct · 10:00 – 12:00 hs",
    "creada": "2026-10-11T22:07:09Z",
    "leida": false
  }
]
```

### `POST /notificaciones/leidas` — Marcar todas como leídas

Marca como leídas todas las notificaciones del usuario autenticado. Responde 204.

### `POST /notificaciones/enviar-pendientes` — Enviar avisos de reservas próximas

Envía los avisos que correspondan en ese momento y devuelve `{ "enviados": <cantidad> }`. La API ya lo hace sola; este endpoint es para un cron externo (ver *Despliegue en Render*). Requiere el header `X-Cron-Secret` igual a la variable `CRON_SECRET`; si no coincide, responde 403.
