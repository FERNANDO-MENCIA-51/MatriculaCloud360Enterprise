/* ============================================================
   TRIGGERS: seguridad.users (Auditoria)
   Sprint 3 - MatriculaCloud360Enterprise
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1. AUDITORIA INSERT */
CREATE OR ALTER TRIGGER seguridad.trg_users_audit_insert
ON seguridad.users
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, new_data, executed_by)
    SELECT @user_id,
           'seguridad.users',
           'INSERT',
           i.id,
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i;
END
GO

/* 2. AUDITORIA UPDATE */
CREATE OR ALTER TRIGGER seguridad.trg_users_audit_update
ON seguridad.users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, new_data, executed_by)
    SELECT @user_id,
           'seguridad.users',
           'UPDATE',
           i.id,
           (SELECT * FROM deleted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id;
END
GO

/* 3. AUDITORIA DELETE */
CREATE OR ALTER TRIGGER seguridad.trg_users_audit_delete
ON seguridad.users
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, executed_by)
    SELECT @user_id,
           'seguridad.users',
           'DELETE',
           d.id,
           (SELECT * FROM deleted x WHERE x.id = d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM deleted d;
END
GO

PRINT 'Triggers de seguridad.users creados correctamente.';
GO