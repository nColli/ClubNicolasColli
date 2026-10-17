# ClubNicolasColli — Backend

API REST en **FastAPI** + **SQLAlchemy** sobre una base **PostgreSQL**. La API y la base se despliegan en **Render**. **Firebase** se usa para verificar a los usuarios (Auth) y para enviar las notificaciones push (Cloud Messaging).

```
backend/
├── api/                 ← API REST (FastAPI). Referencia de endpoints: api/README.md
│   ├── app/             ← código de la API
│   ├── requirements.txt
│   └── .env.example     ← plantilla de variables de entorno
└── database/
    ├── schema.sql       ← crea las tablas (fuente de verdad del modelo de datos)
    ├── seed.sql         ← datos de prueba: 3 sedes, horarios y 7 espacios
    ├── migracion_*.sql  ← solo para bases creadas con versiones anteriores del schema
    └── run_schema.py    ← ejecuta un .sql contra la base del DATABASE_URL
```

**Requisitos previos:** Python 3.12 o superior con pip, Git, y cuentas gratuitas en [Firebase](https://console.firebase.google.com) y [Render](https://dashboard.render.com).

**Orden de los pasos:**

1. [Firebase](#1-firebase): crear el proyecto y descargar la clave de la cuenta de servicio.
2. [Base de datos en Render](#2-base-de-datos-en-render).
3. [Entorno virtual y dependencias](#3-entorno-virtual-y-dependencias).
4. [Variables de entorno](#4-variables-de-entorno-backendapienv).
5. [Crear las tablas con `run_schema.py`](#5-crear-las-tablas-con-run_schemapy).
6. [Correr la API en local](#6-correr-la-api-en-local).
7. [Desplegar la API en Render](#7-desplegar-la-api-en-render).

Todos los comandos parten de la raíz del repositorio clonado.

---

## 1. Firebase

La app y el backend tienen que usar **el mismo proyecto de Firebase**: la API solo acepta tokens emitidos por el proyecto de su cuenta de servicio.

### 1.1 Crear el proyecto

1. Entrar a <https://console.firebase.google.com> → **Crear un proyecto**. Nombre sugerido: `clubnicolascolli`. Google Analytics es opcional.
2. Habilitar el login con email y contraseña: **Compilación → Authentication → Comenzar → Método de acceso → Correo electrónico/contraseña → Habilitar → Guardar**.
3. Cloud Messaging no necesita configuración: la API envía los push con la API HTTP v1 de FCM, que viene habilitada en los proyectos nuevos. Se puede comprobar en **Configuración del proyecto → Cloud Messaging**, donde "API de Firebase Cloud Messaging (V1)" debe figurar como *Habilitada*.

La app Flutter se registra en este mismo proyecto más adelante, con `flutterfire configure` (ver [flutter_app/README.md](../flutter_app/README.md#2-configurar-firebase)).

### 1.2 Descargar la clave de la cuenta de servicio

La API usa el SDK de Firebase Admin para verificar los ID tokens y enviar los push. Para eso necesita una cuenta de servicio:

1. **Configuración del proyecto** (ícono ⚙) → **Cuentas de servicio** → **Firebase Admin SDK**.
2. **Generar nueva clave privada** → **Generar clave**. Se descarga un JSON.

Del JSON se usan tres campos, que van en el `.env` del paso 4: `project_id`, `client_email` y `private_key`.

> ⚠️ El JSON da acceso de administrador al proyecto: **no se sube al repositorio**. `backend/api/.gitignore` ya ignora los `*.json` y el `.env`.

---

## 2. Base de datos en Render

### 2.1 Crear la base

1. Entrar a <https://dashboard.render.com> → **New → Postgres**.
2. Completar:
   - **Name:** por ejemplo `clubnicolascolli-db`.
   - **Region:** cualquiera, pero **anotala**: la API (paso 7) tiene que ir en la misma región.
   - **PostgreSQL Version:** la que viene por defecto.
   - **Plan:** Free.
3. **Create Database** y esperar a que el estado pase a *Available*.

### 2.2 Copiar las URLs de conexión

En la página de la base, botón **Connect** (sección *Connections*), hay dos URLs:

| URL | Para qué se usa |
|---|---|
| **External Database URL** | Conectarse desde tu PC: `run_schema.py` y la API corriendo en local (paso 4). |
| **Internal Database URL** | La API desplegada en Render (paso 7). Solo funciona desde servicios de Render en la misma región. |

Las dos tienen la forma `postgresql://usuario:contraseña@host/base`. No hace falta agregarles nada: el código cambia el prefijo al driver `psycopg2` y agrega `sslmode=require`.

> El plan Free de Render tiene fecha de vencimiento; se ve en el dashboard de la base. Si vence, se crea una nueva y se repiten los pasos 4 y 5.

---

## 3. Entorno virtual y dependencias

```bash
cd backend/api
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

En Windows, si `python3` no existe, usar `python` (o `py`).

| Paquete | Para qué |
|---|---|
| `fastapi[standard]` | Framework de la API, servidor `uvicorn` y el comando `fastapi` |
| `SQLAlchemy` | Acceso a la base (ORM) |
| `psycopg2-binary` | Driver de PostgreSQL (también lo usa `run_schema.py`) |
| `firebase-admin` | Verificar tokens de Firebase y enviar push |
| `python-dotenv` | Leer el archivo `.env` |

Este mismo entorno virtual se usa para `run_schema.py` (paso 5): no hace falta otro.

---

## 4. Variables de entorno (`backend/api/.env`)

```bash
cd backend/api
cp .env.example .env               # Windows: copy .env.example .env
```

Completar `backend/api/.env`:

| Variable | Valor |
|---|---|
| `DATABASE_URL` | **External Database URL** de Render (paso 2.2) |
| `FIREBASE_PROJECT_ID` | Campo `project_id` del JSON de la cuenta de servicio |
| `FIREBASE_CLIENT_EMAIL` | Campo `client_email` del JSON |
| `FIREBASE_PRIVATE_KEY` | Campo `private_key` del JSON, tal cual: una sola línea, con los `\n`, **entre comillas dobles** |
| `AVISOS_INTERVALO_SEGUNDOS` | Opcional. Cada cuántos segundos se revisa si hay recordatorios push para enviar (por defecto `300`, 5 minutos). Para una demo conviene bajarlo, por ejemplo a `10` |

Este es el único `.env` que se usa: lo leen la API y `run_schema.py`.

---

## 5. Crear las tablas con `run_schema.py`

`run_schema.py` ejecuta un archivo `.sql` contra la base del `DATABASE_URL` de `backend/api/.env`. Sin argumentos ejecuta `schema.sql`.

Con el entorno virtual de la API activado (paso 3):

```bash
cd backend/database
python run_schema.py               # crea las tablas (schema.sql)
python run_schema.py seed.sql      # carga los datos de prueba
```

Sin activar el entorno, desde `backend/database`: `../api/.venv/bin/python run_schema.py` (Windows: `..\api\.venv\Scripts\python run_schema.py`).

Cada ejecución correcta imprime, por ejemplo, `schema.sql ejecutado correctamente.`

- **`schema.sql`** habilita la extensión `btree_gist` (la usa la constraint que impide reservas superpuestas) y crea las tablas `USUARIO`, `SEDE`, `HORARIO_SEDE`, `ESPACIO_DEPORTIVO`, `RESERVA`, `DISPOSITIVO` y `NOTIFICACION`.
  ⚠️ Antes de crearlas **borra las tablas existentes y todos sus datos**. Ejecutarlo solo para crear la base o empezar de cero.
- **`seed.sql`** carga 3 sedes (Morón, Ramos Mejía y Castelar), sus horarios (lunes a viernes de 8 a 23, sábados y domingos de 9 a 20) y 7 espacios deportivos. Se ejecuta **una sola vez** después de `schema.sql`; si se repite, falla por ids duplicados. Para recargarlo, volver a ejecutar primero `schema.sql`.
- **`migracion_*.sql`** solo sirven para actualizar una base creada con una versión anterior del schema. Una base nueva **no** las necesita.

Los usuarios no se cargan con SQL: se crean al registrarse desde la app.

---

## 6. Correr la API en local

```bash
cd backend/api
source .venv/bin/activate          # Windows: .venv\Scripts\activate
fastapi dev app/main.py
```

- <http://localhost:8000/health> → `{"status":"ok"}`
- <http://localhost:8000/docs> → Swagger UI (documentación OpenAPI interactiva)
- <http://localhost:8000/openapi.json> → especificación OpenAPI

Al arrancar, la API inicializa Firebase Admin (si falta alguna variable `FIREBASE_*`, se detiene con un error que la nombra) y lanza la tarea que cada 5 minutos (o lo que diga `AVISOS_INTERVALO_SEGUNDOS`) revisa si hay recordatorios push para enviar.

`fastapi dev` escucha solo en `localhost`, que alcanza para el emulador de Android (lo ve como `10.0.2.2`). Para probar desde un **celular físico** en la misma red Wi-Fi:

```bash
fastapi dev app/main.py --host 0.0.0.0
```

y correr la app con la IP de la PC (ver [flutter_app/README.md](../flutter_app/README.md#3-elegir-la-api)).

### Probar los endpoints protegidos desde Swagger

Los endpoints de usuarios, reservas, dispositivos y notificaciones piden un ID token de Firebase. Para probarlos en `/docs`:

1. Tener un usuario registrado: lo más simple es registrarse desde la app.
2. Pedir un ID token a Firebase con el email y la contraseña de ese usuario. `<WEB_API_KEY>` es la **Clave de API web** de **Configuración del proyecto → General**:

   ```bash
   curl -s "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=<WEB_API_KEY>" \
     -H "Content-Type: application/json" \
     -d '{"email":"usuario@mail.com","password":"la-contraseña","returnSecureToken":true}'
   ```

3. Copiar el valor de `idToken` de la respuesta, tocar **Authorize** en Swagger y pegarlo (sin `Bearer`). El token dura 1 hora.

---

## 7. Desplegar la API en Render

Render construye la API desde GitHub, así que el código tiene que estar subido al repositorio.

1. En <https://dashboard.render.com> → **New → Web Service** → conectar la cuenta de GitHub y elegir el repositorio.
2. Configurar:

   | Campo | Valor |
   |---|---|
   | **Language** | Python 3 |
   | **Branch** | `main` |
   | **Region** | La misma que la base (paso 2.1) |
   | **Root Directory** | `backend/api` |
   | **Build Command** | `pip install -r requirements.txt` |
   | **Start Command** | `fastapi run app/main.py --port $PORT` |
   | **Instance Type** | Free |

3. En **Environment Variables**, cargar las cuatro variables:

   | Variable | Valor |
   |---|---|
   | `DATABASE_URL` | **Internal Database URL** de la base (paso 2.2) |
   | `FIREBASE_PROJECT_ID` | Igual que en el `.env` |
   | `FIREBASE_CLIENT_EMAIL` | Igual que en el `.env` |
   | `FIREBASE_PRIVATE_KEY` | El valor de `private_key` **sin las comillas** del `.env` (con los `\n` o con saltos de línea reales; los dos formatos funcionan) |

   También se puede usar **Add from .env** y pegar el contenido del `.env`, cambiando después `DATABASE_URL` por la Internal Database URL.

4. Opcional, en **Advanced → Health Check Path:** `/health`.
5. **Deploy Web Service**. Cuando termina, la API queda en `https://<nombre-del-servicio>.onrender.com`. Comprobar `https://<nombre-del-servicio>.onrender.com/health` y `/docs`.

Cada push a `main` vuelve a desplegar la API automáticamente. El despliegue **no toca la base**: las tablas se crean una sola vez desde la PC con `run_schema.py` (paso 5).

### Plan Free: mantener la API despierta

En el plan Free, Render suspende el servicio después de 15 minutos sin tráfico: el primer request siguiente tarda hasta un minuto y, mientras está suspendido, **no se envían los recordatorios push**. Para evitarlo, crear un cron gratuito en <https://cron-job.org> que cada 5 minutos haga `GET https://<nombre-del-servicio>.onrender.com/health`.

---

## Cambios en el modelo de datos

La fuente de verdad del modelo es [`database/schema.sql`](database/schema.sql). Los modelos de `api/app/models.py` solo mapean esas tablas: la API no crea ni modifica tablas.

Para cambiar el modelo: modificar `schema.sql` y el modelo correspondiente en `app/models.py`. En una base con datos que no se quiere recrear, aplicar el mismo cambio con un script `ALTER TABLE` nuevo (como los `migracion_*.sql`) y ejecutarlo con `python run_schema.py <archivo>.sql`.

---

## Problemas comunes

| Síntoma | Causa y solución |
|---|---|
| `RuntimeError: Falta DATABASE_URL` | No existe `backend/api/.env` o la variable está vacía. |
| `RuntimeError: Faltan variables de entorno: FIREBASE_...` | Falta alguna variable de Firebase en el `.env` (local) o en *Environment* (Render). |
| Error al iniciar al cargar el certificado / la clave privada | `FIREBASE_PRIVATE_KEY` está incompleta: copiar el valor entero, desde `-----BEGIN` hasta `END PRIVATE KEY-----\n`, entre comillas dobles en el `.env`. |
| `run_schema.py` no se conecta (`could not translate host name`, timeout) | Se usó la Internal Database URL desde la PC: usar la **External**. |
| La API en Render no se conecta a la base | La Internal Database URL solo funciona en la misma región. Usar la misma región o la External Database URL. |
| `duplicate key value violates unique constraint` al ejecutar `seed.sql` | Los datos de prueba ya estaban cargados. Ejecutar `schema.sql` y después `seed.sql`. |
| `ZoneInfoNotFoundError: America/Argentina/Buenos_Aires` (Windows) | Windows no trae la base de zonas horarias: `pip install tzdata` en el entorno virtual. |
| Todos los endpoints protegidos responden `401 Token inválido` | La app y la API usan proyectos de Firebase distintos. El `project_id` de la cuenta de servicio tiene que coincidir con el de `flutter_app/lib/firebase_options.dart`. |
| `GET /usuarios/me` responde 404 | El usuario existe en Firebase pero no en la base (por ejemplo, porque se recreó la base). Borrarlo en **Authentication → Users** y registrarse de nuevo desde la app. |
| El primer request a Render tarda o da timeout | El servicio estaba suspendido (plan Free). Abrir `/health` y esperar a que responda. |

---

Referencia de endpoints, autenticación y notificaciones push: [api/README.md](api/README.md).
