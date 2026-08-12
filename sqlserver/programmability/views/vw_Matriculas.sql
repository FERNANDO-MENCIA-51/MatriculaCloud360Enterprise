/* VISTA: vw_Matriculas - Detalle completo de matriculas
  Dependencias: fn_CalcularComision */

USE MatriculaCloud360;
GO

CREATE OR ALTER VIEW dbo.vw_Matriculas
AS
SELECT
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
INNER JOIN operaciones.students s ON e.student_id = s.id AND s.deleted_at IS NULL
INNER JOIN academico.careers c ON e.career_id = c.id AND c.deleted_at IS NULL
INNER JOIN academico.branches b ON e.branch_id = b.id AND b.deleted_at IS NULL
INNER JOIN operaciones.promoters p ON e.promoter_id = p.id AND p.deleted_at IS NULL
INNER JOIN academico.academic_periods ap ON e.period_id = ap.id
INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id;
GO