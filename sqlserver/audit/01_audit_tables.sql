/* ============================================================
   SCRIPT DE AUDITORIA - 01: TABLAS DE AUDITORIA
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Extiende la tabla auditoria.audit_logs para soportar la
   auditoria completa basada en triggers:
     - record_id   : id del registro afectado
     - old_data    : valor anterior del registro (JSON)
     - new_data    : valor nuevo del registro (JSON)
     - executed_by : usuario de SQL Server que ejecuto la accion
   ============================================================ */

USE MatriculaCloud360;
GO

/* 1. Extender auditoria.audit_logs con columnas de detalle */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('auditoria.audit_logs')
                 AND name = 'record_id')
BEGIN
    ALTER TABLE auditoria.audit_logs ADD record_id INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('auditoria.audit_logs')
                 AND name = 'old_data')
BEGIN
    ALTER TABLE auditoria.audit_logs ADD old_data NVARCHAR(MAX) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('auditoria.audit_logs')
                 AND name = 'new_data')
BEGIN
    ALTER TABLE auditoria.audit_logs ADD new_data NVARCHAR(MAX) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('auditoria.audit_logs')
                 AND name = 'executed_by')
BEGIN
    ALTER TABLE auditoria.audit_logs ADD executed_by NVARCHAR(128) NULL;
END
GO

/* 2. Indice de soporte para las consultas de auditoria */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_audit_logs_table_action'
                 AND object_id = OBJECT_ID('auditoria.audit_logs'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_audit_logs_table_action
    ON auditoria.audit_logs (table_name, action_date DESC)
    INCLUDE (operation, record_id);
END
GO

PRINT 'Tablas de auditoria del Sprint 3 preparadas correctamente.';
GO
