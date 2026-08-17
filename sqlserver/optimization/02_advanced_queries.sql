/* ============================================================
   SCRIPT DE OPTIMIZACION - 02: CONSULTAS ANALITICAS AVANZADAS
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Consultas para la caracterizacion del negocio usando:
     - CTE (Common Table Expressions)
     - Funciones de ventana (ROW_NUMBER, RANK, LAG, SUM OVER)
     - Funciones agregadas (COUNT, SUM, AVG, MIN, MAX)
   Cada consulta incluye un marcador --MARKER_Qn usado por
   optimization/03_performance_tests.sql para las pruebas
   comparativas antes/despues de los indices.
   ============================================================ */

USE MatriculaCloud360;
GO

/* ============================================================
   Q1 - MATRICULA DETALLADA (misma logica que vw_Matriculas)
   Consulta de mayor frecuencia: detalle completo de matriculas
   con 7 JOINs y calculo de comision.
   ============================================================ */
PRINT '=== Q1: Matricula detallada ===';
SELECT
    e.enrollment_code,
    CONCAT(s.first_name, ' ', s.last_name, ' (', s.dni, ')') AS student,
    c.name AS career,
    b.name AS branch,
    p.full_name AS promoter,
    ap.name AS period,
    ac.name AS campaign,
    e.amount,
    dbo.fn_CalcularComision(e.id) AS commission
FROM operaciones.enrollments e --MARKER_Q1
INNER JOIN operaciones.students s ON e.student_id = s.id AND s.deleted_at IS NULL
INNER JOIN academico.careers c ON e.career_id = c.id AND c.deleted_at IS NULL
INNER JOIN academico.branches b ON e.branch_id = b.id AND b.deleted_at IS NULL
INNER JOIN operaciones.promoters p ON e.promoter_id = p.id AND p.deleted_at IS NULL
INNER JOIN academico.academic_periods ap ON e.period_id = ap.id AND ap.deleted_at IS NULL
INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id AND ac.deleted_at IS NULL
ORDER BY e.enrollment_date DESC;
GO

/* ============================================================
   Q2 - COMISIONES CRITICAS: comision generada por promotor
   y por campana, con ranking (RANK) para identificar los
   promotores de mayor comision (oportunidades de optimizacion).
   ============================================================ */
PRINT '=== Q2: Comisiones criticas por promotor ===';
;WITH ComisionesPorPromotor AS (
    SELECT
        p.id AS promoter_id,
        p.full_name AS promoter,
        ac.id AS campaign_id,
        ac.name AS campaign,
        COUNT(e.id) AS total_enrollments,
        SUM(e.amount * ac.commission_percentage / 100.0) AS total_commission
    FROM operaciones.enrollments e --MARKER_Q2
    INNER JOIN operaciones.promoters p ON e.promoter_id = p.id AND p.deleted_at IS NULL
    INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id AND ac.deleted_at IS NULL
    GROUP BY p.id, p.full_name, ac.id, ac.name
)
SELECT
    promoter,
    campaign,
    total_enrollments,
    CAST(total_commission AS DECIMAL(10,2)) AS total_commission,
    RANK() OVER (ORDER BY total_commission DESC) AS ranking_comision
FROM ComisionesPorPromotor
ORDER BY ranking_comision;
GO

/* ============================================================
   Q3 - SERIE TEMPORAL: matriculas por periodo con variacion
   usando LAG (funcion de ventana) para medir crecimiento
   periodo a periodo.
   ============================================================ */
PRINT '=== Q3: Evolucion de matriculas por periodo ===';
;WITH MatriculasPorPeriodo AS (
    SELECT
        ap.id AS period_id,
        ap.name AS period,
        COUNT(e.id) AS total_enrollments,
        SUM(e.amount) AS total_amount
    FROM operaciones.enrollments e --MARKER_Q3
    INNER JOIN academico.academic_periods ap ON e.period_id = ap.id AND ap.deleted_at IS NULL
    GROUP BY ap.id, ap.name
)
SELECT
    period,
    total_enrollments,
    CAST(total_amount AS DECIMAL(12,2)) AS total_amount,
    LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) AS prev_enrollments,
    total_enrollments - LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) AS variacion_matriculas,
    CASE
        WHEN LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) = 0 THEN NULL
        ELSE CAST((total_enrollments - LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id)) * 100.0
              / LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) AS DECIMAL(8,2))
    END AS crecimiento_pct
FROM MatriculasPorPeriodo
ORDER BY period_id;
GO

/* ============================================================
   Q4 - ESTUDIANTES MATRICULADOS (misma logica que
   vw_EstudiantesMatriculados): conteo y monto total por
   estudiante con CTE.
   ============================================================ */
PRINT '=== Q4: Estudiantes con sus matriculas ===';
;WITH ResumenEstudiantes AS (
    SELECT
        s.id AS student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student,
        COUNT(e.id) AS total_enrollments,
        SUM(e.amount) AS total_investment,
        MAX(e.enrollment_date) AS last_enrollment_date
    FROM operaciones.students s --MARKER_Q4
    INNER JOIN operaciones.enrollments e ON s.id = e.student_id
    WHERE s.deleted_at IS NULL
    GROUP BY s.id, s.first_name, s.last_name
)
SELECT *
FROM ResumenEstudiantes
ORDER BY total_investment DESC;
GO

/* ============================================================
   Q5 - ANALISIS POR SEDE Y CARRERA con ROLLUP:
   totales por sede, por carrera y gran total (funciones
   agregadas + GROUP BY ROLLUP).
   ============================================================ */
PRINT '=== Q5: Matriculas por sede y carrera (ROLLUP) ===';
SELECT
    COALESCE(b.name, 'TODAS LAS SEDES') AS branch,
    COALESCE(c.name, 'TODAS LAS CARRERAS') AS career,
    COUNT(e.id) AS total_enrollments,
    CAST(SUM(e.amount) AS DECIMAL(12,2)) AS total_amount
FROM operaciones.enrollments e --MARKER_Q5
INNER JOIN academico.branches b ON e.branch_id = b.id AND b.deleted_at IS NULL
INNER JOIN academico.careers c ON e.career_id = c.id AND c.deleted_at IS NULL
GROUP BY ROLLUP (b.name, c.name)
ORDER BY GROUPING(b.name), GROUPING(c.name), b.name, c.name;
GO

/* ============================================================
   INDICADORES INSTITUCIONALES (KPIs globales)
   CTE + funciones agregadas para monitoreo de la organizacion.
   ============================================================ */
PRINT '=== Indicadores institucionales ===';
;WITH KPIs AS (
    SELECT
        (SELECT COUNT(*) FROM operaciones.students WHERE deleted_at IS NULL) AS total_estudiantes,
        (SELECT COUNT(*) FROM operaciones.enrollments) AS total_matriculas,
        (SELECT COUNT(*) FROM academico.careers WHERE deleted_at IS NULL) AS total_carreras,
        (SELECT COUNT(*) FROM academico.branches WHERE deleted_at IS NULL) AS total_sedes,
        (SELECT COUNT(*) FROM academico.admission_campaigns WHERE is_active = 1 AND deleted_at IS NULL) AS campanas_activas,
        (SELECT COUNT(*) FROM operaciones.promoters WHERE deleted_at IS NULL) AS total_promotores
),
Montos AS (
    SELECT
        SUM(amount) AS ingreso_total,
        AVG(amount) AS ticket_promedio,
        MIN(amount) AS matricula_minima,
        MAX(amount) AS matricula_maxima
    FROM operaciones.enrollments
)
SELECT
    k.total_estudiantes,
    k.total_matriculas,
    k.total_carreras,
    k.total_sedes,
    k.campanas_activas,
    k.total_promotores,
    CAST(m.ingreso_total AS DECIMAL(12,2)) AS ingreso_total,
    CAST(m.ticket_promedio AS DECIMAL(10,2)) AS ticket_promedio,
    CAST(m.matricula_minima AS DECIMAL(10,2)) AS matricula_minima,
    CAST(m.matricula_maxima AS DECIMAL(10,2)) AS matricula_maxima,
    CAST(m.ingreso_total / NULLIF(k.total_matriculas, 0) AS DECIMAL(10,2)) AS ingreso_por_matricula
FROM KPIs k
CROSS JOIN Montos m;
GO

/* ============================================================
   COMPLEMENTARIA - Participacion por campana (funcion de
   ventana SUM OVER): % de ingresos de cada campana.
   ============================================================ */
PRINT '=== Participacion por campana ===';
;WITH IngresosCampana AS (
    SELECT
        ac.name AS campaign,
        SUM(e.amount) AS campaign_amount
    FROM operaciones.enrollments e
    INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id
    GROUP BY ac.name
)
SELECT
    campaign,
    CAST(campaign_amount AS DECIMAL(12,2)) AS campaign_amount,
    CAST(campaign_amount * 100.0 / SUM(campaign_amount) OVER () AS DECIMAL(6,2)) AS participacion_pct
FROM IngresosCampana
ORDER BY participacion_pct DESC;
GO

/* ============================================================
   COMPLEMENTARIA - Promedio movil del monto de matricula
   (AVG OVER con ventana de filas).
   ============================================================ */
PRINT '=== Promedio movil (3 matriculas) del monto ===';
SELECT
    enrollment_code,
    amount,
    CAST(AVG(amount) OVER (ORDER BY id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS DECIMAL(10,2)) AS promedio_movil_3
FROM operaciones.enrollments
ORDER BY id;
GO

/* ============================================================
   COMPLEMENTARIA - Subconsulta CORRELACIONADA de T-SQL:
   monto de cada matricula frente al promedio de su carrera
   (la subconsulta interna referencia la fila externa e.career_id)
   ============================================================ */
PRINT '=== Correlacionada: matricula vs promedio de su carrera ===';
SELECT
    e.enrollment_code,
    c.name AS career,
    e.amount,
    (SELECT AVG(e2.amount) FROM operaciones.enrollments e2 WHERE e2.career_id = e.career_id) AS promedio_carrera,
    CAST(e.amount - (SELECT AVG(e2.amount) FROM operaciones.enrollments e2 WHERE e2.career_id = e.career_id) AS DECIMAL(10,2)) AS diferencia
FROM operaciones.enrollments e
INNER JOIN academico.careers c ON e.career_id = c.id
ORDER BY c.name, e.enrollment_code;
GO

PRINT 'Consultas analiticas del Sprint 3 ejecutadas correctamente.';
GO