/* ============================================================
   TRIGGER: academico.courses - Soft Delete
   Sprint 3 - MatriculaCloud360Enterprise
   INSTEAD OF DELETE: convierte el DELETE fisico en borrado logico.
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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

PRINT 'Trigger soft-delete de academico.courses creado correctamente.';
GO