/* PROCEDIMIENTO: usp_ListarEstudiantes
   DESCRIPCION: Lista estudiantes con filtro opcional de eliminados */

USE MatriculaCloud360;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ListarEstudiantes
    @incluir_eliminados BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @incluir_eliminados = 1
        BEGIN
            SELECT id, dni, first_name, last_name, personal_email, phone, deleted_at
            FROM operaciones.students
            ORDER BY id;
        END
        ELSE
        BEGIN
            SELECT id, dni, first_name, last_name, personal_email, phone
            FROM operaciones.students
            WHERE deleted_at IS NULL
            ORDER BY id;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO