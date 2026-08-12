/* PROCEDIMIENTO: usp_ActualizarEstudiante
   DESCRIPCION: Actualiza datos de un estudiante existente */

USE MatriculaCloud360;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ActualizarEstudiante
    @id INT,
    @first_name VARCHAR(100),
    @last_name VARCHAR(100),
    @personal_email VARCHAR(100),
    @phone VARCHAR(20) = NULL,
    @deleted_at DATETIME = NULL
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

        -- Validar email unico excluyendo el propio registro
        IF EXISTS (SELECT 1 FROM operaciones.students
                   WHERE personal_email = @personal_email AND id != @id)
        BEGIN
            RAISERROR('El correo electronico ya esta siendo usado por otro estudiante.', 16, 1);
            RETURN;
        END

        UPDATE operaciones.students
        SET first_name = @first_name,
            last_name = @last_name,
            personal_email = @personal_email,
            phone = @phone,
            deleted_at = @deleted_at
        WHERE id = @id;

        INSERT INTO auditoria.audit_logs (user_id, table_name, operation)
        VALUES (1, 'operaciones.students', 'UPDATE');

        PRINT 'Estudiante actualizado exitosamente.';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO