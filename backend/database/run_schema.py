"""Ejecuta un script SQL en la base del DATABASE_URL de backend/api/.env.

    python run_schema.py              # schema.sql (¡borra y recrea las tablas!)
    python run_schema.py seed.sql     # datos de prueba

Usa el entorno virtual de la API (psycopg2 y python-dotenv ya están ahí).
"""

import os
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

CARPETA = Path(__file__).parent

load_dotenv(CARPETA.parent / "api" / ".env")
url = os.getenv("DATABASE_URL")
if not url:
    sys.exit("Falta DATABASE_URL en backend/api/.env")
# Render exige SSL (salvo que la URL indique otro sslmode)
if "sslmode=" not in url:
    url += "&sslmode=require" if "?" in url else "?sslmode=require"

archivo = CARPETA / (sys.argv[1] if len(sys.argv) > 1 else "schema.sql")
conn = psycopg2.connect(url)
try:
    # "with conn" hace commit si todo sale bien y rollback si algo falla
    with conn, conn.cursor() as cursor:
        cursor.execute(archivo.read_text(encoding="utf-8"))
    print(f"{archivo.name} ejecutado correctamente.")
except psycopg2.Error as e:
    sys.exit(f"Error al ejecutar {archivo.name}: {e}")
finally:
    conn.close()
