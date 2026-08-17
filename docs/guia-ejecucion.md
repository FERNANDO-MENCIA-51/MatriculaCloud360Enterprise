# Guía de ejecución

Pasos para levantar el proyecto MatriculaCloud360Enterprise desde cero, conectar con el cliente SQL y verificar que todo funciona correctamente.

---

## 1. Prerrequisitos

- **Docker Desktop** instalado y en ejecución.
- **Docker Compose** (incluido en Docker Desktop).
- Cliente SQL: **Azure Data Studio** o **SQL Server Management Studio (SSMS)**.

---

## 2. Levantar el entorno

Desde la raíz del repositorio:

```bash
docker compose --env-file docker/.env -f docker/docker-compose.yml up -d
```

Verificar que el contenedor está corriendo:

```bash
docker ps
```

Debes ver el contenedor `sqlserver_matricula` con el puerto **1433** publicado.

Para ver el progreso de la inicialización:

```bash
docker logs -f sqlserver_matricula
```

> La inicialización completa ejecuta 24 scripts en orden: DDL, DML, programmability, auditoría, optimización, seguridad, mantenimiento y testing. Tarda entre 1 y 2 minutos.

---

## 3. Conexión al servidor

Usa tu cliente SQL favorito con estos datos:

| Campo | Valor |
|---|---|
| Servidor | `localhost,1433` |
| Autenticación | SQL Login |
| Usuario | `sa` |
| Contraseña | `Admin2026` |

---

## 4. Verificar que todo funciona

Una vez conectado, ejecuta las siguientes consultas para confirmar que la base está lista:

```sql
-- Ver bases de datos
SELECT name FROM sys.databases;

-- Usar la base del proyecto
USE MatriculaCloud360;
GO

-- Ver los esquemas
SELECT name FROM sys.schemas;

-- Ver las tablas por esquema
SELECT s.name AS esquema, t.name AS tabla
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;

-- Ver los triggers (deberían ser 18)
SELECT OBJECT_SCHEMA_NAME(parent_id) AS esquema,
       OBJECT_NAME(parent_id) AS tabla,
       name AS trigger_
FROM sys.triggers
ORDER BY tabla;

-- Ver los índices creados (deberían ser 13)
SELECT OBJECT_NAME(i.object_id) AS tabla, i.name AS indice
FROM sys.indexes i
WHERE i.name LIKE 'IX_%' AND i.database_id = DB_ID('MatriculaCloud360')
ORDER BY tabla, indice;

-- Ver los usuarios de base de datos
SELECT name AS usuario, type_desc
FROM sys.database_principals
WHERE type IN ('S', 'U', 'G') AND name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys');

-- Ver las pruebas ejecutadas (deberían ser 35/35 PASS)
SELECT category AS suite,
       COUNT(*) AS pruebas,
       SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS pasaron,
       SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END) AS fallaron
FROM testing.test_results
GROUP BY category;

-- Ver el detalle de las pruebas
SELECT test_name, category, result, detail
FROM testing.test_results
ORDER BY category, test_name;
```

---

## 5. Ejecutar la demostración completa

El archivo `DEMOSTRACION_SPRINT3.sql` contiene una demostración paso a paso de todas las funcionalidades del Sprint 3:

```sql
-- Ejecutar el script de demostración
:r DEMOSTRACION_SPRINT3.sql
```

O desde Azure Data Studio / SSMS: abrir el archivo y ejecutarlo completo.

La demostración incluye:

1. Inventario de los 18 triggers.
2. Auditoría INSERT/UPDATE/DELETE sobre `operaciones.students`.
3. Bitácora generada con `executed_by`, `old_data`, `new_data`.
4. Soft-delete sobre `academico.branches`.
5. Verificación de que la fila persiste con `deleted_at`.
6. Consulta de la bitácora del soft-delete.
7. Restauración de la sede eliminada.
8. Consultas analíticas: indicadores institucionales (agregadas + CTE)
9. Q2 - Comisiones por promotor con `RANK`.
10. Q3 - Serie temporal con `LAG`.
11. Subconsulta correlacionada: matrícula vs promedio de carrera.
12. Medición en vivo de Q1 con estadísticas de tiempo y E/S.
13. Evidencia ANTES/DESPUÉS de los índices.
14. CPU acumulado por consulta analítica.
15. Planes de ejecución de las consultas.
16. Consumo por tabla (filas y tamaño en MB).
17. Uso de los índices implementados.
18. Seguridad: perfil Promotor (lo que puede hacer).
19. Seguridad: perfil Promotor (lo que NO puede hacer).
20. Seguridad: perfil Coordinador.
21. Seguridad: perfil Administrador.
22. Estrategia de respaldo FULL + DIFF + LOG.
23. Bitácora de mantenimiento.
24. Mantenimiento de índices.
25. Integridad física y lógica (`DBCC CHECKDB`).
26. Respaldos generados.
27. Simulación de pérdida y restauración.
28. Resultado de las pruebas integrales 35/35.

---

## 6. Reiniciar desde cero

Si necesitas borrar los datos y volver a inicializar:

```bash
docker compose --env-file docker/.env -f docker/docker-compose.yml down -v
docker compose --env-file docker/.env -f docker/docker-compose.yml up -d
```

> El flag `-v` elimina el volumen de datos de SQL Server. Úsalo solo si quieres empezar desde cero.

---

## 7. Solución de problemas

### El contenedor no levanta

```bash
# Ver los logs del contenedor
docker logs sqlserver_matricula
```

Verifica que Docker Desktop esté corriendo y que el puerto 1433 no esté ocupado.

### No puedo conectarme desde SSMS / Azure Data Studio

- Asegúrate de que el contenedor esté corriendo (`docker ps`).
- Verifica la contraseña en `docker/.env`.
- Usa `localhost,1433` como servidor (no solo `localhost`).

### Las pruebas dan FAIL

Asegúrate de ejecutar el proyecto desde cero con `down -v` y `up -d`. Las pruebas se ejecutan automáticamente al final de la inicialización.

### La restauración se cuelga

Después de una restauración, la conexión se corta. Reconecta y ejecuta las consultas de verificación nuevamente.
