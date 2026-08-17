/* PROCEDIMIENTO: usp_ObtenerMatricula
   DESCRIPCION: Obtiene detalle completo de una matricula por ID o codigo */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ObtenerMatricula
    @enrollment_id INT = NULL,
    @enrollment_code VARCHAR(20) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @enrollment_id IS NULL AND @enrollment_code IS NULL
        BEGIN
            RAISERROR('Debe proporcionar un ID o codigo de matricula.', 16, 1);
            RETURN;
        END

        SELECT
            e.id,
            e.enrollment_code,
            CONCAT(s.first_name, ' ', s.last_name, ' (', s.dni, ')') AS student,
            c.name AS career,
            b.name AS branch,
            p.full_name AS promoter,
            ap.name AS period,
            ac.name AS campaign,
            e.amount,
            dbo.fn_CalcularComision(e.id) AS commission,
            e.enrollment_date
        FROM operaciones.enrollments e
        INNER JOIN operaciones.students s ON e.student_id = s.id
        INNER JOIN academico.careers c ON e.career_id = c.id
        INNER JOIN academico.branches b ON e.branch_id = b.id
        INNER JOIN operaciones.promoters p ON e.promoter_id = p.id
        INNER JOIN academico.academic_periods ap ON e.period_id = ap.id
        INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id
        WHERE (e.id = @enrollment_id OR @enrollment_id IS NULL)
          AND (e.enrollment_code = @enrollment_code OR @enrollment_code IS NULL);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO