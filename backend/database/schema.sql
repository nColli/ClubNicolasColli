-- Crea la base desde cero (¡borra las tablas y sus datos!):
--   python run_schema.py

CREATE EXTENSION IF NOT EXISTS btree_gist;
DROP TABLE IF EXISTS DISPOSITIVO;
DROP TABLE IF EXISTS RESERVA;
DROP TABLE IF EXISTS ESPACIO_DEPORTIVO;
DROP TABLE IF EXISTS HORARIO_SEDE;
DROP TABLE IF EXISTS SEDE;
DROP TABLE IF EXISTS USUARIO;

CREATE TABLE IF NOT EXISTS USUARIO (
    uid VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255) NOT NULL,
    dni VARCHAR(8) NOT NULL, -- 7 u 8 dígitos
    fecha_nacimiento DATE NOT NULL,
    CONSTRAINT usuario_dni_unico UNIQUE (dni)
);

CREATE TABLE IF NOT EXISTS SEDE (
    id SERIAL PRIMARY KEY,
    nombre varchar(100) NOT NULL,
    direccion varchar(200) NOT NULL,
    imagen_url VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS HORARIO_SEDE (
    id SERIAL PRIMARY KEY,
    sede_id INT NOT NULL REFERENCES sede(id) ON DELETE CASCADE,
    dia_semana SMALLINT NOT NULL, -- 1 = LUNES, 7 = DOMINGO
    hora_apertura SMALLINT NOT NULL, -- 0 a 23
    hora_cierre SMALLINT NOT NULL -- 1 a 24
);

CREATE TABLE IF NOT EXISTS ESPACIO_DEPORTIVO (
    id SERIAL PRIMARY KEY,
    sede_id INT NOT NULL REFERENCES sede(id),
    tipo VARCHAR(50) NOT NULL, -- Fútbol, Tenis, Paddle, etc.
    numero SMALLINT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    precio_hora NUMERIC(10, 2) NOT NULL,
    UNIQUE (sede_id, numero)
);

CREATE TABLE IF NOT EXISTS RESERVA (
  id           SERIAL PRIMARY KEY,
  espacio_id   INT NOT NULL REFERENCES espacio_deportivo(id),
  usuario_id   VARCHAR(255) NOT NULL REFERENCES USUARIO(uid),
  fecha        DATE NOT NULL,
  hora_inicio  SMALLINT NOT NULL,
  hora_fin     SMALLINT NOT NULL,
  -- Marcan si ya se envió el aviso push de 24 h y de 1 h antes del inicio.
  -- La campana de la app muestra las reservas futuras con algún aviso enviado.
  aviso_24h_enviado BOOLEAN NOT NULL DEFAULT FALSE,
  aviso_1h_enviado  BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT reserva_sin_superposicion EXCLUDE USING gist (
    espacio_id WITH =,
    fecha WITH =,
    int4range(hora_inicio, hora_fin) WITH &&
  )
);

-- Celulares donde el usuario recibe notificaciones push (token de FCM).
-- Si otro usuario inicia sesión en el mismo celular, el token pasa a ser suyo.
CREATE TABLE IF NOT EXISTS DISPOSITIVO (
  token        VARCHAR(512) PRIMARY KEY,
  usuario_id   VARCHAR(255) NOT NULL REFERENCES USUARIO(uid) ON DELETE CASCADE
);
