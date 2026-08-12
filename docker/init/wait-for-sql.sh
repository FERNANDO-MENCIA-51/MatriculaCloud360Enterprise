#!/bin/bash
# wait-for-sql.sh
# Espera a que SQL Server esté disponible para aceptar conexiones.
# Usa las variables de entorno del contenedor (SA_PASSWORD definida en docker-compose.yml).

HOST="${DB_SERVER:-localhost}"
USER="${DB_USER:-sa}"
PASSWORD="${SA_PASSWORD:-${DB_PASSWORD:-}}"

echo "Esperando a que SQL Server en $HOST esté disponible..."

until /opt/mssql-tools18/bin/sqlcmd -S "$HOST" -U "$USER" -P "$PASSWORD" -C -Q "SELECT 1" &> /dev/null
do
  echo "SQL Server no está listo todavía. Reintentando en 3 segundos..."
  sleep 3
done

echo "¡SQL Server está listo y en línea!"