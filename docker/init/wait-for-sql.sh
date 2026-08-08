#!/bin/bash
# wait-for-sql.sh

HOST="${DB_SERVER:-localhost}"
USER="${DB_USER:-sa}"
PASSWORD="${DB_PASSWORD}"

echo "Esperando a que SQL Server en $HOST esté disponible..."

until /opt/mssql-tools18/bin/sqlcmd -S "$HOST" -U "$USER" -P "$PASSWORD" -C -Q "SELECT 1" &> /dev/null
do
  echo "SQL Server no está listo todavía. Reintentando en 3 segundos..."
  sleep 3
done

echo "¡SQL Server está listo y en línea!"

#Ejecución automática del script de inicialización si está montado
if [ -f /docker-entrypoint-initdb.d/init.sql ]; then
    echo "Ejecutando script de inicialización (init.sql)..."
    /opt/mssql-tools18/bin/sqlcmd -S "$HOST" -U "$USER" -P "$PASSWORD" -C -i /docker-entrypoint-initdb.d/init.sql
    echo "¡Inicialización de la base de datos completada!"
fi