#!/usr/bin/env python3
"""Script to initialize the IRRd database."""

import time
import sys
import psycopg2
import psycopg2.extensions
import psycopg2.sql
import yaml


def execute_sql_command(
    db_host, db_admin_database, db_admin_user, db_admin_password, db_sql_command, max_retries=10, retry_interval=5
):
    """Executes an SQL command (like CREATE DATABASE) on a PostgreSQL server,
       waiting for the database to be ready.

    Args:
        host: Hostname or IP of the PostgreSQL server.
        admin_database: Name of an existing database for the initial connection
            (typically 'postgres' or a similar administrative database).
        admin_user: Username with sufficient privileges to create databases.
        admin_password: Password for the admin_user.
        sql_command: The SQL command to execute.
        max_retries: Maximum number of connection attempts (default 10).
        retry_interval: Time in seconds between retries (default 5).

    Returns:
        True if successful, False otherwise. Prints informative messages.
    """

    retries = 0
    while retries < max_retries:
        try:
            # Attempt connection to the admin database
            conn = psycopg2.connect(
                host=db_host, database=db_admin_database, user=db_admin_user, password=db_admin_password
            )
            conn.set_session(autocommit=True)
            cur = conn.cursor()

            # Execute the SQL command
            cur.execute(db_sql_command)
            print("SQL command executed successfully.")
            return True

        except psycopg2.OperationalError:
            print(
                f"Database not ready yet. Retrying in {retry_interval} seconds... "
                f"(Attempt {retries + 1}/{max_retries})"
            )
            time.sleep(retry_interval)  # Wait before retrying
            retries += 1

        except psycopg2.errors.DuplicateDatabase:
            print("Database already exists, skipping...")
            return True

        except psycopg2.errors.DuplicateObject:
            print("Object already exists, skipping...")
            return True

    # Max retries reached
    print("Error: Database connection could not be established " "after multiple retries.")
    return False


try:
    with open("/opt/irrd/irrd.yaml", "r", encoding="utf-8") as yaml_conf:
        irrd_conf = yaml.safe_load(yaml_conf)
except FileNotFoundError:
    print("Error: Could not find the configuration file at /opt/irrd/irrd.yaml.")
    sys.exit(1)

dsn = psycopg2.extensions.parse_dsn(irrd_conf["irrd"]["database_url"])
host = dsn["host"]
admin_database = dsn["dbname"]
admin_user = dsn["user"]
admin_password = dsn["password"]

# Create the database first
sql_command = psycopg2.sql.SQL("""
CREATE DATABASE {database};
""").format(database=psycopg2.sql.Identifier(admin_database))
execute_sql_command(host, admin_database, admin_user, admin_password, sql_command)

# Do the rest
sql_command = psycopg2.sql.SQL("""
CREATE ROLE {user} WITH LOGIN ENCRYPTED PASSWORD {password};
GRANT ALL PRIVILEGES ON DATABASE {database} TO {user};
CREATE EXTENSION IF NOT EXISTS pgcrypto;
GRANT ALL ON SCHEMA public TO {user};
""").format(
    user=psycopg2.sql.Identifier(admin_user),
    password=psycopg2.sql.Literal(admin_password),
    database=psycopg2.sql.Identifier(admin_database),
)
execute_sql_command(host, admin_database, admin_user, admin_password, sql_command)
