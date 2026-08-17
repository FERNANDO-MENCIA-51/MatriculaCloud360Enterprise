/* ============================================================
   SCRIPT DE MANTENIMIENTO - 02: RESTAURACION Y RECUPERACION
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Procedimientos de recuperacion de la informacion:
     1. usp_RestoreDatabaseFull : restaura un respaldo FULL
     2. usp_RestoreDatabaseDiff : restaura FULL + DIFERENCIAL
     3. usp_RestoreDatabaseWithLog: restaura FULL + LOG(s)

   La restauracion pasa la base a modo SINGLE_USER, la restaura
   con REPLACE y RECOVERY, y la devuelve a MULTI_USER.
   El proceso completo es validado por testing/recovery_tests.sql.
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1. Restauracion de un respaldo FULL (en master y MatriculaCloud360) */
USE master;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RestoreDatabaseFull
    @backup_file NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @file NVARCHAR(500) = @backup_file;

    IF @file IS NULL
    BEGIN
        SELECT TOP 1 @file = bf.physical_device_name
        FROM msdb.dbo.backupset bs
        INNER JOIN msdb.dbo.backupmediafamily bf ON bs.media_set_id = bf.media_set_id
        WHERE bs.database_name = 'MatriculaCloud360'
          AND bs.type = 'D'
        ORDER BY bs.backup_finish_date DESC;
    END

    IF @file IS NULL
    BEGIN
        RAISERROR('No se encontro un respaldo FULL. Ejecute primero usp_BackupDatabaseFull.', 16, 1);
        RETURN;
    END

    ALTER DATABASE MatriculaCloud360 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    SET @sql = N'RESTORE DATABASE MatriculaCloud360 FROM DISK = ''' + @file
             + N''' WITH REPLACE, RECOVERY;';
    EXEC(@sql);

    ALTER DATABASE MatriculaCloud360 SET MULTI_USER;

    SELECT 'Restauracion FULL completada correctamente.' AS resultado, @file AS archivo_restaurado;
END
GO

USE MatriculaCloud360;
GO

/* 2. Restauracion FULL + DIFERENCIAL */
CREATE OR ALTER PROCEDURE dbo.usp_RestoreDatabaseDiff
    @full_file NVARCHAR(500),
    @diff_file NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    IF DB_ID('MatriculaCloud360') IS NOT NULL
    BEGIN
        SET @sql = N'ALTER DATABASE MatriculaCloud360 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
        EXEC(@sql);
    END

    SET @sql = N'RESTORE DATABASE MatriculaCloud360 FROM DISK = ''' + @full_file
             + N''' WITH REPLACE, NORECOVERY;';
    EXEC(@sql);

    SET @sql = N'RESTORE DATABASE MatriculaCloud360 FROM DISK = ''' + @diff_file
             + N''' WITH RECOVERY;';
    EXEC(@sql);

    SET @sql = N'ALTER DATABASE MatriculaCloud360 SET MULTI_USER;';
    EXEC(@sql);

    SELECT 'Restauracion FULL + DIFERENCIAL completada correctamente.' AS resultado;
END
GO

/* 3. Restauracion FULL + LOG(s) */
CREATE OR ALTER PROCEDURE dbo.usp_RestoreDatabaseWithLog
    @full_file NVARCHAR(500),
    @log_file NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    IF DB_ID('MatriculaCloud360') IS NOT NULL
    BEGIN
        SET @sql = N'ALTER DATABASE MatriculaCloud360 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
        EXEC(@sql);
    END

    SET @sql = N'RESTORE DATABASE MatriculaCloud360 FROM DISK = ''' + @full_file
             + N''' WITH REPLACE, NORECOVERY;';
    EXEC(@sql);

    SET @sql = N'RESTORE LOG MatriculaCloud360 FROM DISK = ''' + @log_file
             + N''' WITH RECOVERY;';
    EXEC(@sql);

    SET @sql = N'ALTER DATABASE MatriculaCloud360 SET MULTI_USER;';
    EXEC(@sql);

    SELECT 'Restauracion FULL + LOG completada correctamente.' AS resultado;
END
GO

PRINT 'Procedimientos de restauracion del Sprint 3 creados correctamente.';
PRINT 'Uso: EXEC dbo.usp_RestoreDatabaseFull N''/var/opt/mssql/backup/MatriculaCloud360_FULL_*.bak''';
PRINT 'El proceso de restauracion se valida en testing/recovery_tests.sql.';
GO