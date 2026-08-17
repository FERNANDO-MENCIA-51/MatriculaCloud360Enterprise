# Cómo ejecutar la demostración completa

Guía paso a paso para ejecutar la demostración del proyecto desde Docker hasta las pruebas finales.

---

## Resumen

1. Levantar el entorno con Docker Compose.
2. Conectarse con SSMS o Azure Data Studio.
3. Ejecutar el script de demostración (21 bloques).
4. Verificar los resultados.

---

## Paso 1: Levantar el entorno

```bash
docker compose --env-file docker/.env -f docker/docker-compose.yml up -d
```

Esperar 1 a 2 minutos. Verificar con:

```bash
docker ps
```

---

## Paso 2: Conectarse

| Campo | Valor |
|---|---|
| Servidor | `localhost,1433` |
| Usuario | `sa` |
| Contraseña | `Admin2026` |

---

## Paso 3: Ejecutar la demostración

Abrir `DEMOSTRACION_SPRINT3.sql` y ejecutar bloque por bloque:

| Bloque | Tema | Duración |
|---|---|---|
| 1 | Inventario de 18 triggers | 10 seg |
| 2-3 | Auditoría INSERT/UPDATE/DELETE + bitácora | 20 seg |
| 4-5 | Soft-delete y restauración de sede | 20 seg |
| 6-9 | Indicadores, comisiones (RANK), serie temporal (LAG), subconsulta correlacionada | 1 min |
| 10-12 | ANTES/DESPUÉS índices, CPU acumulado, uso de índices | 1 min |
| 13-16 | Seguridad: Promotor, Coordinador, Administrador | 1 min |
| 17-20 | Respaldo, bitácora, integridad, respaldos generados | 1 min |
| 21 | Simulación de pérdida y restauración | 30 seg |
| 22 | Pruebas integrales 35/35 (después de reconectar) | 20 seg |

**Total: ~8 minutos**

> **Importante:** Después del bloque 21, la restauración corta la conexión. Reconectar y ejecutar solo el bloque 22.

---

## Paso 4: Verificar resultados

### Ver las 35 pruebas

```sql
SELECT category AS suite,
       COUNT(*) AS pruebas,
       SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS pasaron
FROM testing.test_results
GROUP BY category;
```

### Ver los respaldos

```sql
SELECT database_name, type, backup_finish_date
FROM msdb.dbo.backupset
WHERE database_name = 'MatriculaCloud360'
ORDER BY backup_finish_date DESC;
```

### Ver los índices

```sql
SELECT OBJECT_NAME(i.object_id) AS tabla, i.name AS indice
FROM sys.indexes i
WHERE i.name LIKE 'IX_%' AND i.database_id = DB_ID('MatriculaCloud360')
ORDER BY tabla, indice;
```

---

## Solución de problemas

### No veo los mensajes de estadísticas de CPU

Usar el bloque 11 del script, que consulta `sys.dm_exec_query_stats` directamente.

### La restauración falla

Verificar que existe el respaldo generado en el bloque 17. Si no, ejecutar `EXEC dbo.usp_BackupDatabaseFull` nuevamente.

### Las pruebas no están después de restaurar

La restauración devuelve la base al estado del respaldo, donde sí existen las pruebas. Reconectar y ejecutar el bloque 22.
