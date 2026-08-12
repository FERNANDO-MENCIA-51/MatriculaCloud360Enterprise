/* PROCEDIMIENTO: usp_RegistrarEstudiante
   DESCRIPCION: Registra un nuevo estudiante con validaciones*/

USE MatriculaCloud360;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegistrarEstudiante
    @dni VARCHAR(15),
    @first_name VARCHAR(100),
    @last_name VARCHAR(100),
    @personal_email VARCHAR(100),
    @phone VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar DNI unico
        IF EXISTS (SELECT 1 FROM operaciones.students WHERE dni = @dni)
        BEGIN
            RAISERROR('El DNI ingresado ya se encuentra registrado.', 16, 1);
            RETURN;
        END

        -- Validar email unico
        IF EXISTS (SELECT 1 FROM operaciones.students WHERE personal_email = @personal_email)
        BEGIN
            RAISERROR('El correo electronico ingresado ya se encuentra registrado.', 16, 1);
            RETURN;
        END

        INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
        VALUES (@dni, @first_name, @last_name, @personal_email, @phone);

        DECLARE @NewId INT = SCOPE_IDENTITY();

        INSERT INTO auditoria.audit_logs (user_id, table_name, operation)
        VALUES (1, 'operaciones.students', 'INSERT');

        SELECT @NewId AS new_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO