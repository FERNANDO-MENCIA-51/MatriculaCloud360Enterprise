/* ============================================================
   SCRIPT DE MANTENIMIENTO - 01: ESTRATEGIA DE RESPALDO
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Estrategia de respaldo (tipo empresarial):
     1. FULL    : diario (base de respaldo)
     2. DIFF    : cada 6 horas entre fulls
     3. LOG     : cada hora (solo si el modelo de recuperacion es FULL)
   Los respaldos se almacenan en /var/opt/mssql/backup/
   (directorio del contenedor Docker, montado y persistido).
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1. Procedimiento: respaldo FULL */
CREATE OR ALTER PROCEDURE dbo.usp_BackupDatabaseFull
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @file NVARCHAR(500) = N'/var/opt/mssql/backup/MatriculaCloud360_FULL_'
                                 + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + N'.bak';

    BACKUP DATABASE MatriculaCloud360
    TO DISK = @file
    WITH NAME = N'MatriculaCloud360-FullBackup',
         DESCRIPTION = N'Respaldo FULL - Sprint 3',
         CHECKSUM, COMPRESSION, INIT, STATS = 10;

    SELECT @file AS backup_file, GETDATE() AS backup_date;
END
GO

/* 2. Procedimiento: respaldo DIFERENCIAL */
CREATE OR ALTER PROCEDURE dbo.usp_BackupDatabaseDifferential
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @file NVARCHAR(500) = N'/var/opt/mssql/backup/MatriculaCloud360_DIFF_'
                                 + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + N'.dif';

    BACKUP DATABASE MatriculaCloud360
    TO DISK = @file
    WITH DIFFERENTIAL,
         NAME = N'MatriculaCloud360-DiffBackup',
         DESCRIPTION = N'Respaldo DIFERENCIAL - Sprint 3',
         CHECKSUM, COMPRESSION, INIT, STATS = 10;

    SELECT @file AS backup_file, GETDATE() AS backup_date;
END
GO

/* 3. Procedimiento: respaldo del LOG de transacciones */
CREATE OR ALTER PROCEDURE dbo.usp_BackupDatabaseLog
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @file NVARCHAR(500) = N'/var/opt/mssql/backup/MatriculaCloud360_LOG_'
                                 + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + N'.trn';

    BACKUP LOG MatriculaCloud360
    TO DISK = @file
    WITH NAME = N'MatriculaCloud360-LogBackup',
         DESCRIPTION = N'Respaldo LOG - Sprint 3',
         CHECKSUM, COMPRESSION, INIT, STATS = 10;

    SELECT @file AS backup_file, GETDATE() AS backup_date;
END
GO

/* 4. Ejecutar un respaldo FULL para dejar evidencia operativa */
EXEC dbo.usp_BackupDatabaseFull;
GO

/* 5. Verificacion de los respaldos existentes */
SELECT
    bs.database_name,
    bs.type AS tipo_respaldo,
    CASE bs.type
        WHEN 'D' THEN 'FULL'
        WHEN 'I' THEN 'DIFFERENCIAL'
        WHEN 'L' THEN 'LOG'
    END AS tipo_descripcion,
    bs.backup_finish_date,
    bs.backup_size,
    bf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bf ON bs.media_set_id = bf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360'
ORDER BY bs.backup_finish_date DESC;
GO

PRINT 'Estrategia de respaldo del Sprint 3 ejecutada correctamente.';
GO