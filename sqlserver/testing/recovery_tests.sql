/* ============================================================
   SCRIPT DE TESTING - 03: PRUEBAS DE RESPALDO Y RECUPERACION
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Proceso validado en este script:
     1. Se genera un respaldo FULL de la base.
     2. Se inserta un registro marcador (simulando datos nuevos).
     3. Se restaura el respaldo FULL.
     4. Se valida que el marcador desaparece y que la base
        conserva la informacion del momento del respaldo.
   Al ejecutarse al final de la inicializacion, los resultados de
   las pruebas anteriores quedan incluidos en el respaldo y se
   conservan tras la restauracion.
   ============================================================ */

USE master;
GO

/* 1. Generar el respaldo FULL (deja evidencia en msdb) */
PRINT '>>> Paso 1: Generando respaldo FULL...';
EXEC dbo.usp_BackupDatabaseFull;
GO

/* 2. Identificar el ultimo respaldo FULL */
DECLARE @full_file NVARCHAR(500);

SELECT TOP 1 @full_file = bf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bf ON bs.media_set_id = bf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360'
  AND bs.type = 'D'
ORDER BY bs.backup_finish_date DESC;

IF @full_file IS NULL
BEGIN
    RAISERROR('No se encontro un respaldo FULL para restablecer.', 16, 1);
    RETURN;
END

PRINT 'Respaldo a restaurar: ' + @full_file;
GO

/* 3. Insertar un registro marcador (datos posteriores al respaldo) */
USE MatriculaCloud360;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '88880001')
BEGIN
    INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
    VALUES ('88880001', 'Marcador', 'Recovery', 'marcador.recovery@gmail.com', '999888777');
    PRINT '>>> Paso 3: Registro marcador 88880001 insertado.';
END
GO

/* 4. Restaurar el respaldo FULL */
USE master;
GO

DECLARE @full_file NVARCHAR(500);

SELECT TOP 1 @full_file = bf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bf ON bs.media_set_id = bf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360'
  AND bs.type = 'D'
ORDER BY bs.backup_finish_date DESC;

PRINT '>>> Paso 4: Restaurando ' + @full_file;
EXEC dbo.usp_RestoreDatabaseFull @full_file;
GO

/* 5. Validaciones post-restauracion */
USE MatriculaCloud360;
GO

/* 5.1. El registro marcador NO debe existir */
IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '88880001')
    EXEC testing.usp_RecordTest 'R1 Marcador eliminado por restore', 'RECUPERACION', 1,
         'El registro posterior al respaldo no existe (restauracion correcta).';
ELSE
    EXEC testing.usp_RecordTest 'R1 Marcador eliminado por restore', 'RECUPERACION', 0,
         'El registro marcador sobrevivio a la restauracion (error).';
GO

/* 5.2. La informacion del respaldo se conserva */
DECLARE @total_matriculas INT = (SELECT COUNT(*) FROM operaciones.enrollments);
DECLARE @total_estudiantes INT = (SELECT COUNT(*) FROM operaciones.students WHERE deleted_at IS NULL);
DECLARE @det_r2 VARCHAR(500);

IF @total_matriculas > 0 AND @total_estudiantes > 0
BEGIN
    SET @det_r2 = 'Matriculas=' + CAST(@total_matriculas AS VARCHAR(10)) +
                  ', Estudiantes=' + CAST(@total_estudiantes AS VARCHAR(10));
    EXEC testing.usp_RecordTest 'R2 Datos conservados tras restore', 'RECUPERACION', 1, @det_r2;
END
ELSE
    EXEC testing.usp_RecordTest 'R2 Datos conservados tras restore', 'RECUPERACION', 0,
         'La base quedo sin informacion tras la restauracion.';
GO

/* 5.3. La base esta integra y operativa */
BEGIN TRY
    EXEC dbo.usp_CheckDatabaseIntegrity;
    EXEC testing.usp_RecordTest 'R3 Integridad tras restore', 'RECUPERACION', 1, 'DBCC CHECKDB sin errores.';
END TRY
BEGIN CATCH
    DECLARE @err_r3 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'R3 Integridad tras restore', 'RECUPERACION', 0, @err_r3;
END CATCH
GO

/* 6. Resumen de pruebas de recuperacion */
SELECT
    result,
    COUNT(*) AS total
FROM testing.test_results
WHERE category = 'RECUPERACION'
GROUP BY result;
GO

PRINT 'Pruebas de respaldo y recuperacion del Sprint 3 completadas.';
GO