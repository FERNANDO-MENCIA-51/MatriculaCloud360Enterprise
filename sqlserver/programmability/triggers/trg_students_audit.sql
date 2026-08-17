/* ============================================================
   TRIGGERS: operaciones.students (Auditoria + Soft Delete)
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   1. trg_students_soft_delete   : INSTEAD OF DELETE -> borrado logico
   2. trg_students_audit_insert  : AFTER INSERT  -> auditoria
   3. trg_students_audit_update  : AFTER UPDATE  -> auditoria (detecta DELETE logico)
   4. trg_students_audit_delete  : AFTER DELETE  -> auditoria (respaldo)
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1. BORRADO LOGICO: convierte el DELETE fisico en UPDATE deleted_at */
CREATE OR ALTER TRIGGER operaciones.trg_students_soft_delete
ON operaciones.students
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.deleted_at = GETDATE()
    FROM operaciones.students s
    INNER JOIN deleted d ON s.id = d.id
    WHERE s.deleted_at IS NULL;
END
GO

/* 2. AUDITORIA INSERT */
CREATE OR ALTER TRIGGER operaciones.trg_students_audit_insert
ON operaciones.students
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, new_data, executed_by)
    SELECT @user_id,
           'operaciones.students',
           'INSERT',
           i.id,
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i;
END
GO

/* 3. AUDITORIA UPDATE: si deleted_at paso de NULL a valor -> operacion DELETE */
CREATE OR ALTER TRIGGER operaciones.trg_students_audit_update
ON operaciones.students
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, new_data, executed_by)
    SELECT @user_id,
           'operaciones.students',
           CASE WHEN d.deleted_at IS NULL AND i.deleted_at IS NOT NULL THEN 'DELETE' ELSE 'UPDATE' END,
           i.id,
           (SELECT * FROM deleted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id;
END
GO

/* 4. AUDITORIA DELETE (respaldo: solo dispara si se omite el INSTEAD OF DELETE) */
CREATE OR ALTER TRIGGER operaciones.trg_students_audit_delete
ON operaciones.students
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, executed_by)
    SELECT @user_id,
           'operaciones.students',
           'DELETE',
           d.id,
           (SELECT * FROM deleted x WHERE x.id = d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM deleted d;
END
GO

PRINT 'Triggers de operaciones.students creados correctamente.';
GO