-- Agrega las notificaciones que el usuario ve en la app (campana del inicio).
-- Ejecutar en una base creada antes de este cambio (una base nueva ya lo
-- tiene en schema.sql):
--   python run_schema.py migracion_004_notificaciones_app.sql

CREATE TABLE IF NOT EXISTS NOTIFICACION (
  id           SERIAL PRIMARY KEY,
  usuario_id   VARCHAR(255) NOT NULL REFERENCES USUARIO(uid) ON DELETE CASCADE,
  reserva_id   INT REFERENCES RESERVA(id) ON DELETE SET NULL,
  titulo       VARCHAR(200) NOT NULL,
  cuerpo       VARCHAR(500) NOT NULL,
  creada       TIMESTAMPTZ NOT NULL DEFAULT now(),
  leida        BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS notificacion_usuario_creada
  ON NOTIFICACION (usuario_id, creada DESC);
