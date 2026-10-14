import os
import sys
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("Missing DATABASE_URL in .env file.")

# Ensure SSL mode is enabled for Render connections
if "sslmode=" not in DATABASE_URL:
    DATABASE_URL += "?sslmode=require" if "?" not in DATABASE_URL else "&sslmode=require"


def execute_sql_file(file_path: str | Path):
    path = Path(file_path)

    if not path.is_file():
        raise FileNotFoundError(f"SQL file not found at: {path.resolve()}")

    print(f"Reading SQL script from: {path.resolve()}")
    with open(path, mode="r", encoding="utf-8") as f:
        sql_script = f.read()

    print("Connecting to Render PostgreSQL...")
    conn = psycopg2.connect(DATABASE_URL)

    try:
        with conn:
            with conn.cursor() as cursor:
                print("Executing SQL statements...")
                # psycopg2 executes multi-statement SQL strings seamlessly
                cursor.execute(sql_script)

                # 1. Show the command status message (e.g. 'CREATE TABLE')
                print(f"Server response: {cursor.statusmessage}")

                # 2. Check if the script produced any output rows
                if cursor.description is not None:
                    columns = [desc[0] for desc in cursor.description]
                    rows = cursor.fetchall()
                    print(f"Columns: {columns}")
                    print("Rows:")
                    for row in rows:
                        print(row)
                else:
                    print("(Query did not return data rows — standard for CREATE/ALTER statements")
    
        print("Schema and tables created successfully!")

    except psycopg2.Error as err:
        print(f"Error executing SQL: {err}")
        sys.exit(1)

    finally:
        conn.close()


if __name__ == "__main__":
    # Por defecto ejecuta schema.sql; se puede pasar otro archivo, ej: python run_schema.py seed.sql
    target_sql_file = sys.argv[1] if len(sys.argv) > 1 else "schema.sql"
    execute_sql_file(target_sql_file)