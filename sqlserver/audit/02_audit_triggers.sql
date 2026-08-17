/* ============================================================
   SCRIPT DE AUDITORIA - 02: TRIGGERS DE AUDITORIA (CONSOLIDADO)
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Consolidado de los triggers definidos individualmente en
   sqlserver/programmability/triggers/trg_*.sql
     - Tablas criticas auditadas (INSERT/UPDATE/DELETE):
         operaciones.students, operaciones.promoters,
         operaciones.enrollments, seguridad.users
     - Soft delete (INSTEAD OF DELETE -> deleted_at):
         operaciones.students, operaciones.promoters,
         academico.branches, academico.careers,
         academico.teachers, academico.courses
   Dependencias: audit/01_audit_tables.sql
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ================= operaciones.students ================= */

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

CREATE OR ALTER TRIGGER operaciones.trg_students_audit_insert
ON operaciones.students
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, new_data, executed_by)
    SELECT @user_id, 'operaciones.students', 'INSERT', i.id,
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i;
END
GO

CREATE OR ALTER TRIGGER operaciones.trg_students_audit_update
ON operaciones.students
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, new_data, executed_by)
    SELECT @user_id, 'operaciones.students',
           CASE WHEN d.deleted_at IS NULL AND i.deleted_at IS NOT NULL THEN 'DELETE' ELSE 'UPDATE' END,
           i.id,
           (SELECT * FROM deleted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id;
END
GO

CREATE OR ALTER TRIGGER operaciones.trg_students_audit_delete
ON operaciones.students
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, executed_by)
    SELECT @user_id, 'operaciones.students', 'DELETE', d.id,
           (SELECT * FROM deleted x WHERE x.id = d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM deleted d;
END
GO

/* ================= operaciones.promoters ================= */

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

CREATE OR ALTER TRIGGER operaciones.trg_promoters_audit_insert
ON operaciones.promoters
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, new_data, executed_by)
    SELECT @user_id, 'operaciones.promoters', 'INSERT', i.id,
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i;
END
GO

CREATE OR ALTER TRIGGER operaciones.trg_promoters_audit_update
ON operaciones.promoters
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, new_data, executed_by)
    SELECT @user_id, 'operaciones.promoters',
           CASE WHEN d.deleted_at IS NULL AND i.deleted_at IS NOT NULL THEN 'DELETE' ELSE 'UPDATE' END,
           i.id,
           (SELECT * FROM deleted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id;
END
GO

CREATE OR ALTER TRIGGER operaciones.trg_promoters_audit_delete
ON operaciones.promoters
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, executed_by)
    SELECT @user_id, 'operaciones.promoters', 'DELETE', d.id,
           (SELECT * FROM deleted x WHERE x.id = d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM deleted d;
END
GO

/* ================= operaciones.enrollments ================= */

CREATE OR ALTER TRIGGER operaciones.trg_enrollments_audit_insert
ON operaciones.enrollments
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, new_data, executed_by)
    SELECT @user_id, 'operaciones.enrollments', 'INSERT', i.id,
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i;
END
GO

CREATE OR ALTER TRIGGER operaciones.trg_enrollments_audit_update
ON operaciones.enrollments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, new_data, executed_by)
    SELECT @user_id, 'operaciones.enrollments', 'UPDATE', i.id,
           (SELECT * FROM deleted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id;
END
GO

CREATE OR ALTER TRIGGER operaciones.trg_enrollments_audit_delete
ON operaciones.enrollments
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, executed_by)
    SELECT @user_id, 'operaciones.enrollments', 'DELETE', d.id,
           (SELECT * FROM deleted x WHERE x.id = d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM deleted d;
END
GO

/* ================= seguridad.users ================= */

CREATE OR ALTER TRIGGER seguridad.trg_users_audit_insert
ON seguridad.users
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, new_data, executed_by)
    SELECT @user_id, 'seguridad.users', 'INSERT', i.id,
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i;
END
GO

CREATE OR ALTER TRIGGER seguridad.trg_users_audit_update
ON seguridad.users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, new_data, executed_by)
    SELECT @user_id, 'seguridad.users', 'UPDATE', i.id,
           (SELECT * FROM deleted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.id = i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id;
END
GO

CREATE OR ALTER TRIGGER seguridad.trg_users_audit_delete
ON seguridad.users
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @user_id INT = COALESCE(
        (SELECT TOP 1 id FROM seguridad.users WHERE username = SUSER_SNAME()), 1);

    INSERT INTO auditoria.audit_logs (user_id, table_name, operation, record_id, old_data, executed_by)
    SELECT @user_id, 'seguridad.users', 'DELETE', d.id,
           (SELECT * FROM deleted x WHERE x.id = d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           SUSER_SNAME()
    FROM deleted d;
END
GO

/* ================= Soft delete: catalogos academicos ================= */

CREATE OR ALTER TRIGGER academico.trg_branches_soft_delete
ON academico.branches
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE b
    SET b.deleted_at = GETDATE()
    FROM academico.branches b
    INNER JOIN deleted d ON b.id = d.id
    WHERE b.deleted_at IS NULL;
END
GO

CREATE OR ALTER TRIGGER academico.trg_careers_soft_delete
ON academico.careers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
    SET c.deleted_at = GETDATE()
    FROM academico.careers c
    INNER JOIN deleted d ON c.id = d.id
    WHERE c.deleted_at IS NULL;
END
GO

CREATE OR ALTER TRIGGER academico.trg_teachers_soft_delete
ON academico.teachers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t
    SET t.deleted_at = GETDATE()
    FROM academico.teachers t
    INNER JOIN deleted d ON t.id = d.id
    WHERE t.deleted_at IS NULL;
END
GO

CREATE OR ALTER TRIGGER academico.trg_courses_soft_delete
ON academico.courses
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
    SET c.deleted_at = GETDATE()
    FROM academico.courses c
    INNER JOIN deleted d ON c.id = d.id
    WHERE c.deleted_at IS NULL;
END
GO

PRINT 'Triggers de auditoria y soft-delete del Sprint 3 creados correctamente.';
GO