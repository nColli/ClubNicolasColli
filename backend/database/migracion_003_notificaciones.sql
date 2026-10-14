-- Agrega lo necesario para las notificaciones push de reservas próximas.
-- Ejecutar en una base creada antes de este cambio (una base nueva ya lo
-- tiene en schema.sql):
--   python run_schema.py migracion_003_notificaciones.sql

ALTER TABLE RESERVA ADD COLUMN IF NOT EXISTS aviso_24h_enviado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE RESERVA ADD COLUMN IF NOT EXISTS aviso_1h_enviado BOOLEAN NOT NULL DEFAULT FALSE;

-- Las reservas que ya empezaron no tienen que recibir avisos
UPDATE RESERVA SET aviso_24h_enviado = TRUE, aviso_1h_enviado = TRUE
WHERE fecha < (now() AT TIME ZONE 'America/Argentina/Buenos_Aires')::date;

CREATE TABLE IF NOT EXISTS DISPOSITIVO (
  token        VARCHAR(512) PRIMARY KEY,
  usuario_id   VARCHAR(255) NOT NULL REFERENCES USUARIO(uid) ON DELETE CASCADE,
  actualizado  TIMESTAMPTZ NOT NULL DEFAULT now()
);
