/* PROCEDIMIENTO: usp_RegistrarMatricula
   DESCRIPCION: Registra una matricula con transaccion y validaciones */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegistrarMatricula
    @enrollment_code VARCHAR(20),
    @student_id INT,
    @career_id INT,
    @branch_id INT,
    @promoter_id INT,
    @period_id INT,
    @campaign_id INT,
    @amount DECIMAL(10,2)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- 1. Validar estudiante existente y no eliminado
        IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE id = @student_id AND deleted_at IS NULL)
        BEGIN
            RAISERROR('El estudiante no existe o se encuentra eliminado.', 16, 1);
            RETURN;
        END

        -- 2. Validar carrera existente y no eliminada
        IF NOT EXISTS (SELECT 1 FROM academico.careers WHERE id = @career_id AND deleted_at IS NULL)
        BEGIN
            RAISERROR('La carrera no existe o se encuentra eliminada.', 16, 1);
            RETURN;
        END

        -- 3. Validar sede existente y no eliminada
        IF NOT EXISTS (SELECT 1 FROM academico.branches WHERE id = @branch_id AND deleted_at IS NULL)
        BEGIN
            RAISERROR('La sede no existe o se encuentra eliminada.', 16, 1);
            RETURN;
        END

        -- 4. Validar promotor existente, asignado a la sede y no eliminado
        IF NOT EXISTS (SELECT 1 FROM operaciones.promoters
                       WHERE id = @promoter_id
                         AND base_branch_id = @branch_id
                         AND deleted_at IS NULL)
        BEGIN
            RAISERROR('El promotor no existe, no pertenece a la sede indicada o esta eliminado.', 16, 1);
            RETURN;
        END

        -- 5. Validar periodo existente, activo y no eliminado
        IF NOT EXISTS (SELECT 1 FROM academico.academic_periods
                       WHERE id = @period_id AND is_active = 1 AND deleted_at IS NULL)
        BEGIN
            RAISERROR('El periodo academico no existe, no esta activo o fue eliminado.', 16, 1);
            RETURN;
        END

        -- 6. Validar campana existente, activa y no eliminada
        IF NOT EXISTS (SELECT 1 FROM academico.admission_campaigns
                       WHERE id = @campaign_id AND is_active = 1 AND deleted_at IS NULL)
        BEGIN
            RAISERROR('La campana de admision no existe, no esta activa o fue eliminada.', 16, 1);
            RETURN;
        END

        -- 7. Validar monto positivo
        IF @amount <= 0
        BEGIN
            RAISERROR('El monto de la matricula debe ser mayor a cero.', 16, 1);
            RETURN;
        END

        -- Iniciar transaccion
        BEGIN TRANSACTION;

        INSERT INTO operaciones.enrollments (
            enrollment_code, student_id, career_id, branch_id,
            promoter_id, period_id, campaign_id, amount
        )
        VALUES (
            @enrollment_code, @student_id, @career_id, @branch_id,
            @promoter_id, @period_id, @campaign_id, @amount
        );

        DECLARE @NewEnrollmentId INT = SCOPE_IDENTITY();
        -- La auditoria la genera el trigger trg_enrollments_audit_insert (Sprint 3)

        COMMIT TRANSACTION;

        SELECT @NewEnrollmentId AS enrollment_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO