-- Agrega el DNI de los usuarios. Ejecutar en una base creada antes de este
-- cambio (una base nueva ya lo tiene en schema.sql):
--   python run_schema.py migracion_002_dni_usuario.sql
--
-- Los usuarios que ya existen quedan sin DNI hasta que lo carguen desde
-- "Editar perfil" en la app. Cuando todos lo tengan, volver a ejecutar este
-- script deja la columna como obligatoria (NOT NULL), igual que en schema.sql.

ALTER TABLE USUARIO ADD COLUMN IF NOT EXISTS dni VARCHAR(8);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'usuario_dni_unico'
  ) THEN
    ALTER TABLE USUARIO ADD CONSTRAINT usuario_dni_unico UNIQUE (dni);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM USUARIO WHERE dni IS NULL) THEN
    ALTER TABLE USUARIO ALTER COLUMN dni SET NOT NULL;
  ELSE
    RAISE NOTICE 'Hay usuarios sin DNI: la columna queda opcional por ahora.';
  END IF;
END $$;
