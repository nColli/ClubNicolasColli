-- Datos de prueba. Ejecutar después de schema.sql:
--   python run_schema.py seed.sql

INSERT INTO SEDE (id, nombre, direccion, imagen_url) VALUES
  (1, 'Morón', 'Av. Rivadavia 17500', 'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?w=800&q=70'),
  (2, 'Ramos Mejía', 'Calle Belgrano 1240', 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&q=70'),
  (3, 'Castelar', 'Av. Santa Rosa 950', 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=800&q=70');
SELECT setval('sede_id_seq', (SELECT MAX(id) FROM SEDE));

-- Lunes a viernes de 8 a 23, sábados y domingos de 9 a 20
INSERT INTO HORARIO_SEDE (sede_id, dia_semana, hora_apertura, hora_cierre)
SELECT s.id, d.dia, CASE WHEN d.dia <= 5 THEN 8 ELSE 9 END, CASE WHEN d.dia <= 5 THEN 23 ELSE 20 END
FROM SEDE s CROSS JOIN generate_series(1, 7) AS d(dia);

INSERT INTO ESPACIO_DEPORTIVO (sede_id, tipo, numero, nombre, precio_hora) VALUES
  (1, 'Fútbol', 1, 'Moron_Rivadavia_17500_Futbol_1', 3000),
  (1, 'Tenis',  2, 'Moron_Rivadavia_17500_Tenis_2', 2500),
  (1, 'Tenis',  3, 'Moron_Rivadavia_17500_Tenis_3', 2500),
  (2, 'Fútbol', 1, 'RamosMejia_Belgrano_1240_Futbol_1', 3200),
  (2, 'Hockey', 2, 'RamosMejia_Belgrano_1240_Hockey_2', 2800),
  (3, 'Paddle', 1, 'Castelar_SantaRosa_950_Paddle_1', 2000),
  (3, 'Golf',   2, 'Castelar_SantaRosa_950_Golf_2', 4000);
