/* PROCEDIMIENTO: usp_EliminarEstudiante
   DESCRIPCION: Eliminacion logica (soft-delete) de un estudiante  */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_EliminarEstudiante
    @id INT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar que el estudiante exista
        IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE id = @id)
        BEGIN
            RAISERROR('El estudiante especificado no existe.', 16, 1);
            RETURN;
        END

        -- Validar que no este ya eliminado
        IF EXISTS (SELECT 1 FROM operaciones.students WHERE id = @id AND deleted_at IS NOT NULL)
        BEGIN
            RAISERROR('El estudiante ya se encuentra eliminado.', 16, 1);
            RETURN;
        END

        UPDATE operaciones.students
        SET deleted_at = GETDATE()
        WHERE id = @id;
        -- La auditoria la genera el trigger trg_students_audit_update (Sprint 3)

        PRINT 'Estudiante eliminado exitosamente (soft-delete).';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO