/* ============================================================
   TRIGGERS: operaciones.promoters (Auditoria + Soft Delete)
   Sprint 3 - MatriculaCloud360Enterprise
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1. BORRADO LOGICO */
CREATE OR ALTER TRIGGER operaciones.trg_promoters_soft_delete
ON operaciones.promoters
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.deleted_at = GETDATE()
    FROM operaciones.promoters p
    INNER JOIN deleted d ON p.id = d.id
    WHERE p.deleted_at IS NULL;
END
GO

/* 2. AUDITORIA INSERT */
CREATE OR ALTER TRIGGER operaciones.trg_promoters_audit_insert
ON operaciones.promoters
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, new_data, executed_by)
    SELECT @user_id,
           'operaciones.promoters',
           'INSERT',
           i.id,
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i;
END
GO

/* 3. AUDITORIA UPDATE */
CREATE OR ALTER TRIGGER operaciones.trg_promoters_audit_update
ON operaciones.promoters
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, new_data, executed_by)
    SELECT @user_id,
           'operaciones.promoters',
           CASE WHEN d.deleted_at IS NULL AND i.deleted_at IS NOT NULL THEN 'DELETE' ELSE 'UPDATE' END,
           i.id,
           (SELECT * FROM deleted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id;
END
GO

/* 4. AUDITORIA DELETE (respaldo) */
CREATE OR ALTER TRIGGER operaciones.trg_promoters_audit_delete
ON operaciones.promoters
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, executed_by)
    SELECT @user_id,
           'operaciones.promoters',
           'DELETE',
           d.id,
           (SELECT * FROM deleted x WHERE x.id = d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM deleted d;
END
GO

PRINT 'Triggers de operaciones.promoters creados correctamente.';
GO