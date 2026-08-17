# Backup y recuperación

Estrategia de respaldo y procedimientos de restauración de la base de datos MatriculaCloud360.

---

## 1. Estrategia de respaldo

Se implementa una estrategia empresarial de tres niveles:

| Tipo | Frecuencia | Descripción |
|---|---|---|
| **FULL** | Diario | Respaldo completo de la base de datos |
| **DIFFERENTIAL** | Cada 6 horas | Solo los cambios desde el último FULL |
| **LOG** | Cada hora | Registro de transacciones para recuperación punto en el tiempo |

Los archivos se almacenan en `/var/opt/mssql/backup/` dentro del contenedor.

---

## 2. Procedimientos de respaldo

### 2.1 Respaldo FULL

```sql
EXEC dbo.usp_BackupDatabaseFull;
```

Genera un archivo `.bak` con nombre `MatriculaCloud360_FULL_yyyyMMdd_HHmmss.bak`.

### 2.2 Respaldo DIFERENCIAL

```sql
EXEC dbo.usp_BackupDatabaseDifferential;
```

Genera un archivo `.dif` con nombre `MatriculaCloud360_DIFF_yyyyMMdd_HHmmss.dif`.

### 2.3 Respaldo de LOG

```sql
EXEC dbo.usp_BackupDatabaseLog;
```

Genera un archivo `.trn` con nombre `MatriculaCloud360_LOG_yyyyMMdd_HHmmss.trn`.

---

## 3. Procedimientos de restauración

### 3.1 Restauración FULL

```sql
EXEC dbo.usp_RestoreDatabaseFull @backup_file = N'/var/opt/mssql/backup/MatriculaCloud360_FULL_xxx.bak';
```

### 3.2 Restauración FULL + DIFERENCIAL

```sql
EXEC dbo.usp_RestoreDatabaseDiff
    @full_file = N'/var/opt/mssql/backup/MatriculaCloud360_FULL_xxx.bak',
    @diff_file = N'/var/opt/mssql/backup/MatriculaCloud360_DIFF_xxx.dif';
```

### 3.3 Restauración FULL + LOG

```sql
EXEC dbo.usp_RestoreDatabaseWithLog
    @full_file = N'/var/opt/mssql/backup/MatriculaCloud360_FULL_xxx.bak',
    @log_file = N'/var/opt/mssql/backup/MatriculaCloud360_LOG_xxx.trn';
```

> **Nota:** La restauración pasa la base a modo `SINGLE_USER`, aplica `REPLACE` y finaliza con `RECOVERY`. Después devuelve la base a `MULTI_USER`.

---

## 4. Ver respaldos existentes

```sql
SELECT bs.database_name,
       CASE bs.type WHEN 'D' THEN 'FULL' WHEN 'I' THEN 'DIFFERENTIAL' WHEN 'L' THEN 'LOG' END AS tipo,
       bs.backup_finish_date,
       bs.backup_size,
       bf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bf ON bs.media_set_id = bf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360'
ORDER BY bs.backup_finish_date DESC;
```

---

## 5. Mantenimiento de índices

### 5.1 Mantenimiento automático

```sql
EXEC dbo.usp_MaintenanceIndexes;
```

El procedimiento recorre todos los índices y aplica:

- **REBUILD** si la fragmentación es mayor al 30%.
- **REORGANIZE** si la fragmentación está entre 5% y 30%.
- **Actualización de estadísticas** al final.

Cada operación queda registrada en `auditoria.maintenance_log`.

### 5.2 Ver bitácora de mantenimiento

```sql
SELECT object_name, operation, fragmentation, run_date
FROM auditoria.maintenance_log
ORDER BY run_date DESC;
```

---

## 6. Verificación de integridad

```sql
EXEC dbo.usp_CheckDatabaseIntegrity;
```

Ejecuta `DBCC CHECKDB` sobre la base de datos y registra el resultado en `auditoria.maintenance_log`.

---

## 7. Simulación de pérdida y recuperación (R1-R3)

El script `sqlserver/testing/recovery_tests.sql` ejecuta automáticamente la siguiente secuencia:

1. Genera un respaldo FULL.
2. Inserta un registro marcador (datos posteriores al respaldo).
3. Restaura el respaldo FULL.
4. Verifica que:
   - **R1**: El marcador desaparece (no existe tras la restauración).
   - **R2**: Los datos del momento del respaldo se conservan.
   - **R3**: `DBCC CHECKDB` no reporta errores.

Para ejecutar las pruebas manualmente:

```sql
:r sqlserver/testing/recovery_tests.sql
```

---

## 8. Notas importantes

- Los respaldos se almacenan dentro del volumen Docker. Si eliminas el volumen con `docker compose down -v`, pierdes los archivos de respaldo.
- Después de una restauración, la conexión se corta. Debes reconectar y ejecutar las consultas de verificación nuevamente.
- Las pruebas de recuperación se ejecutan al final de la inicialización, después de las pruebas funcionales y de seguridad.
