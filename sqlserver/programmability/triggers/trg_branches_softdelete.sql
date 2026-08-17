/* ============================================================
   TRIGGER: academico.branches - Soft Delete
   Sprint 3 - MatriculaCloud360Enterprise
   INSTEAD OF DELETE: convierte el DELETE fisico en borrado logico.
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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

PRINT 'Trigger soft-delete de academico.branches creado correctamente.';
GO