/* ============================================================
   TRIGGER: academico.teachers - Soft Delete
   Sprint 3 - MatriculaCloud360Enterprise
   INSTEAD OF DELETE: convierte el DELETE fisico en borrado logico.
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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

PRINT 'Trigger soft-delete de academico.teachers creado correctamente.';
GO