/* VISTA: vw_EstudiantesMatriculados - Estudiantes con sus matriculas */

USE MatriculaCloud360;
GO

CREATE OR ALTER VIEW dbo.vw_EstudiantesMatriculados
AS
SELECT
    CONCAT(s.first_name, ' ', s.last_name, ' (', s.dni, ')') AS student,
    s.personal_email AS email,
    s.phone,
    COUNT(e.id) AS total_enrollments,
    SUM(e.amount) AS total_investment,
    MAX(e.enrollment_date) AS last_enrollment_date
FROM operaciones.students s
INNER JOIN operaciones.enrollments e ON s.id = e.student_id
WHERE s.deleted_at IS NULL
GROUP BY s.id, s.first_name, s.last_name, s.dni, s.personal_email, s.phone;
GO