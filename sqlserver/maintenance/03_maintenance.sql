/* ============================================================
   SCRIPT DE MANTENIMIENTO - 03: MANTENIMIENTO DE INDICES Y
   CHEQUEO DE INTEGRIDAD
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   - usp_MaintenanceIndexes: REBUILD si fragmentacion > 30%,
     REORGANIZE si fragmentacion entre 5% y 30%, y actualiza
     estadisticas de todos los indices.
   - usp_CheckDatabaseIntegrity: DBCC CHECKDB para validar la
     integridad fisica y logica de la base.
   Cada ejecucion queda registrada en auditoria.maintenance_log.
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1. Tabla de bitacora de mantenimiento */
IF OBJECT_ID('auditoria.maintenance_log', N'U') IS NULL
BEGIN
    CREATE TABLE auditoria.maintenance_log (
        id INT IDENTITY(1,1) PRIMARY KEY,
        object_name NVARCHAR(200) NOT NULL,
        operation VARCHAR(30) NOT NULL,
        fragmentation DECIMAL(5,2) NULL,
        run_date DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

/* 2. Procedimiento: mantenimiento de indices */
CREATE OR ALTER PROCEDURE dbo.usp_MaintenanceIndexes
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @schema_name NVARCHAR(128), @table_name NVARCHAR(128);
    DECLARE @index_name NVARCHAR(128);
    DECLARE @frag DECIMAL(5,2);
    DECLARE @sql NVARCHAR(MAX);

    DECLARE cur_indexes CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
            OBJECT_NAME(ips.object_id) AS table_name,
            i.name AS index_name,
            ips.avg_fragmentation_in_percent
        FROM sys.dm_db_index_physical_stats(DB_ID('MatriculaCloud360'), NULL, NULL, NULL, 'LIMITED') ips
        INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
        WHERE ips.avg_fragmentation_in_percent > 5
          AND ips.index_id > 0
        ORDER BY ips.avg_fragmentation_in_percent DESC;

    OPEN cur_indexes;
    FETCH NEXT FROM cur_indexes INTO @schema_name, @table_name, @index_name, @frag;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @frag > 30
        BEGIN
            -- REBUILD: alta fragmentacion
            SET @sql = N'ALTER INDEX ' + QUOTENAME(@index_name)
                     + N' ON ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)
                     + N' REBUILD;';
            EXEC(@sql);
            INSERT INTO auditoria.maintenance_log (object_name, operation, fragmentation)
            VALUES (@schema_name + N'.' + @table_name + N'.' + @index_name, 'REBUILD', @frag);
        END
        ELSE
        BEGIN
            -- REORGANIZE: fragmentacion moderada
            SET @sql = N'ALTER INDEX ' + QUOTENAME(@index_name)
                     + N' ON ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)
                     + N' REORGANIZE;';
            EXEC(@sql);
            INSERT INTO auditoria.maintenance_log (object_name, operation, fragmentation)
            VALUES (@schema_name + N'.' + @table_name + N'.' + @index_name, 'REORGANIZE', @frag);
        END

        FETCH NEXT FROM cur_indexes INTO @schema_name, @table_name, @index_name, @frag;
    END

    CLOSE cur_indexes;
    DEALLOCATE cur_indexes;

    -- Actualizar estadisticas de todas las tablas
    EXEC sp_MSforeachtable @command1 = 'UPDATE STATISTICS ?';

    PRINT 'Mantenimiento de indices completado.';
END
GO

/* 3. Procedimiento: chequeo de integridad */
CREATE OR ALTER PROCEDURE dbo.usp_CheckDatabaseIntegrity
AS
BEGIN
    SET NOCOUNT ON;

    DBCC CHECKDB(N'MatriculaCloud360') WITH NO_INFOMSGS;

    INSERT INTO auditoria.maintenance_log (object_name, operation, fragmentation)
    VALUES ('MatriculaCloud360', 'DBCC CHECKDB', NULL);

    SELECT 'Integridad de la base verificada (DBCC CHECKDB).' AS resultado;
END
GO

/* 4. Ejecutar el mantenimiento y el chequeo para dejar evidencia */
EXEC dbo.usp_MaintenanceIndexes;
GO

EXEC dbo.usp_CheckDatabaseIntegrity;
GO

/* 5. Bitacora de mantenimiento */
SELECT object_name, operation, fragmentation, run_date
FROM auditoria.maintenance_log
ORDER BY run_date DESC;
GO

PRINT 'Mantenimiento del Sprint 3 ejecutado correctamente.';
GO