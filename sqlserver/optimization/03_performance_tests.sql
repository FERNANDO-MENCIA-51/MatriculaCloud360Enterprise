/* ============================================================
   SCRIPT DE OPTIMIZACION - 03: PRUEBAS COMPARATIVAS DE
   RENDIMIENTO (ANTES / DESPUES DE LOS INDICES)
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Metodologia:
     1. Fase ANTES : se eliminan los indices de la estrategia y
                     se miden Q1..Q5 (tiempo ms + lecturas logicas).
     2. Fase DESPUES: se recrean los indices (01_indexes.sql) y
                     se vuelven a medir las mismas consultas.
     3. Evidencia: resultados persistidos en
                   optimizacion.performance_results y comparativa
                   final mostrada en pantalla.

   Para medir las lecturas logicas se consulta
   sys.dm_exec_query_stats filtrando por el marcador de cada
   consulta (--MARKER_Qn incluido en optimization/02_advanced_queries.sql).
   ============================================================ */

USE MatriculaCloud360;
GO

/* QUOTED_IDENTIFIER ON es requerido para los indices filtrados */
SET QUOTED_IDENTIFIER ON;
GO

/* 1. ESQUEMA Y TABLA DE EVIDENCIA */
IF SCHEMA_ID('optimizacion') IS NULL
    EXEC('CREATE SCHEMA optimizacion');
GO

IF OBJECT_ID('optimizacion.performance_results', N'U') IS NULL
BEGIN
    CREATE TABLE optimizacion.performance_results (
        id INT IDENTITY(1,1) PRIMARY KEY,
        query_name VARCHAR(80) NOT NULL,
        index_phase VARCHAR(20) NOT NULL,
        elapsed_ms INT NOT NULL,
        logical_reads BIGINT NOT NULL,
        run_date DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

/* 2. PROCEDIMIENTO DE MEDICION */
CREATE OR ALTER PROCEDURE optimizacion.usp_MeasureQuery
    @query_name VARCHAR(80),
    @sql NVARCHAR(MAX),
    @marker VARCHAR(60),
    @index_phase VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start DATETIME2, @end DATETIME2;
    DECLARE @elapsed_ms INT;
    DECLARE @reads_before BIGINT, @reads_after BIGINT, @reads BIGINT;

    -- Limpiar cache y buffers para medir en condiciones equivalentes
    DBCC FREEPROCCACHE;
    DBCC DROPCLEANBUFFERS;

    -- Lecturas logicas acumuladas antes de la ejecucion
    SELECT @reads_before = ISNULL(SUM(qs.total_logical_reads), 0)
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
    WHERE t.text LIKE '%' + @marker + '%';

    -- Ejecutar la consulta a medir
    SET @start = SYSUTCDATETIME();
    EXEC sp_executesql @sql;
    SET @end = SYSUTCDATETIME();

    SET @elapsed_ms = DATEDIFF(MICROSECOND, @start, @end) / 1000;

    -- Lecturas logicas acumuladas despues de la ejecucion
    SELECT @reads_after = ISNULL(SUM(qs.total_logical_reads), 0)
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
    WHERE t.text LIKE '%' + @marker + '%';

    SET @reads = @reads_after - @reads_before;
    IF @reads < 0 SET @reads = 0;

    INSERT INTO optimizacion.performance_results (query_name, index_phase, elapsed_ms, logical_reads)
    VALUES (@query_name, @index_phase, @elapsed_ms, @reads);

    PRINT 'Medicion ' + @query_name + ' [' + @index_phase + ']: ' +
          CAST(@elapsed_ms AS VARCHAR(10)) + ' ms, ' +
          CAST(@reads AS VARCHAR(20)) + ' lecturas logicas.';
END
GO

/* ============================================================
   FASE 1 + 2 + 3: definicion de consultas, fase ANTES (sin
   indices), recreacion de indices y fase DESPUES.
   (Variables y ejecuciones en el mismo batch.)
   ============================================================ */
DECLARE @q1 NVARCHAR(MAX) = N'
SELECT e.enrollment_code, CONCAT(s.first_name,'' '',s.last_name) AS student,
       c.name AS career, b.name AS branch, p.full_name AS promoter,
       ap.name AS period, ac.name AS campaign, e.amount,
       dbo.fn_CalcularComision(e.id) AS commission
FROM operaciones.enrollments e --MARKER_Q1
INNER JOIN operaciones.students s ON e.student_id = s.id AND s.deleted_at IS NULL
INNER JOIN academico.careers c ON e.career_id = c.id AND c.deleted_at IS NULL
INNER JOIN academico.branches b ON e.branch_id = b.id AND b.deleted_at IS NULL
INNER JOIN operaciones.promoters p ON e.promoter_id = p.id AND p.deleted_at IS NULL
INNER JOIN academico.academic_periods ap ON e.period_id = ap.id AND ap.deleted_at IS NULL
INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id AND ac.deleted_at IS NULL
ORDER BY e.enrollment_date DESC';

DECLARE @q2 NVARCHAR(MAX) = N'
SELECT p.full_name AS promoter, ac.name AS campaign,
       COUNT(e.id) AS total_enrollments,
       SUM(e.amount * ac.commission_percentage / 100.0) AS total_commission
FROM operaciones.enrollments e --MARKER_Q2
INNER JOIN operaciones.promoters p ON e.promoter_id = p.id AND p.deleted_at IS NULL
INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id AND ac.deleted_at IS NULL
GROUP BY p.full_name, ac.name';

DECLARE @q3 NVARCHAR(MAX) = N'
SELECT ap.name AS period, COUNT(e.id) AS total_enrollments, SUM(e.amount) AS total_amount
FROM operaciones.enrollments e --MARKER_Q3
INNER JOIN academico.academic_periods ap ON e.period_id = ap.id AND ap.deleted_at IS NULL
GROUP BY ap.id, ap.name
ORDER BY ap.id';

DECLARE @q4 NVARCHAR(MAX) = N'
SELECT s.id AS student_id, CONCAT(s.first_name,'' '',s.last_name) AS student,
       COUNT(e.id) AS total_enrollments, SUM(e.amount) AS total_investment
FROM operaciones.students s --MARKER_Q4
INNER JOIN operaciones.enrollments e ON s.id = e.student_id
WHERE s.deleted_at IS NULL
GROUP BY s.id, s.first_name, s.last_name
ORDER BY total_investment DESC';

DECLARE @q5 NVARCHAR(MAX) = N'
SELECT b.name AS branch, c.name AS career,
       COUNT(e.id) AS total_enrollments, SUM(e.amount) AS total_amount
FROM operaciones.enrollments e --MARKER_Q5
INNER JOIN academico.branches b ON e.branch_id = b.id AND b.deleted_at IS NULL
INNER JOIN academico.careers c ON e.career_id = c.id AND c.deleted_at IS NULL
GROUP BY b.name, c.name';

PRINT '>>> FASE ANTES: eliminando indices de la estrategia...';
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_student_id') DROP INDEX IX_enrollments_student_id ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_career_id') DROP INDEX IX_enrollments_career_id ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_branch_id') DROP INDEX IX_enrollments_branch_id ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_promoter_campaign_cover') DROP INDEX IX_enrollments_promoter_campaign_cover ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_period_id') DROP INDEX IX_enrollments_period_id ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_campaign_id') DROP INDEX IX_enrollments_campaign_id ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_enrollment_date') DROP INDEX IX_enrollments_enrollment_date ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_student_cover') DROP INDEX IX_enrollments_student_cover ON operaciones.enrollments;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_students_active_filtered') DROP INDEX IX_students_active_filtered ON operaciones.students;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_promoters_base_branch') DROP INDEX IX_promoters_base_branch ON operaciones.promoters;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_campaigns_active_filtered') DROP INDEX IX_campaigns_active_filtered ON academico.admission_campaigns;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_periods_active_filtered') DROP INDEX IX_periods_active_filtered ON academico.academic_periods;

PRINT '>>> MEDICION FASE ANTES...';
EXEC optimizacion.usp_MeasureQuery 'Q1_MatriculaDetallada', @q1, '%MARKER_Q1%', 'ANTES';
EXEC optimizacion.usp_MeasureQuery 'Q2_ComisionesPromotor', @q2, '%MARKER_Q2%', 'ANTES';
EXEC optimizacion.usp_MeasureQuery 'Q3_SeriesPorPeriodo', @q3, '%MARKER_Q3%', 'ANTES';
EXEC optimizacion.usp_MeasureQuery 'Q4_EstudiantesMatriculados', @q4, '%MARKER_Q4%', 'ANTES';
EXEC optimizacion.usp_MeasureQuery 'Q5_PorSedeYCarrera', @q5, '%MARKER_Q5%', 'ANTES';

PRINT '>>> FASE DESPUES: recreando indices...';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_student_id')
    CREATE NONCLUSTERED INDEX IX_enrollments_student_id ON operaciones.enrollments (student_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_career_id')
    CREATE NONCLUSTERED INDEX IX_enrollments_career_id ON operaciones.enrollments (career_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_branch_id')
    CREATE NONCLUSTERED INDEX IX_enrollments_branch_id ON operaciones.enrollments (branch_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_promoter_campaign_cover')
    CREATE NONCLUSTERED INDEX IX_enrollments_promoter_campaign_cover ON operaciones.enrollments (promoter_id, campaign_id) INCLUDE (student_id, branch_id, period_id, amount);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_period_id')
    CREATE NONCLUSTERED INDEX IX_enrollments_period_id ON operaciones.enrollments (period_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_campaign_id')
    CREATE NONCLUSTERED INDEX IX_enrollments_campaign_id ON operaciones.enrollments (campaign_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_enrollment_date')
    CREATE NONCLUSTERED INDEX IX_enrollments_enrollment_date ON operaciones.enrollments (enrollment_date);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_enrollments_student_cover')
    CREATE NONCLUSTERED INDEX IX_enrollments_student_cover ON operaciones.enrollments (student_id) INCLUDE (amount, enrollment_date);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_students_active_filtered')
    CREATE NONCLUSTERED INDEX IX_students_active_filtered ON operaciones.students (last_name, first_name) INCLUDE (dni, personal_email, phone) WHERE deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_promoters_base_branch')
    CREATE NONCLUSTERED INDEX IX_promoters_base_branch ON operaciones.promoters (base_branch_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_campaigns_active_filtered')
    CREATE NONCLUSTERED INDEX IX_campaigns_active_filtered ON academico.admission_campaigns (is_active) INCLUDE (name, commission_percentage) WHERE deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_periods_active_filtered')
    CREATE NONCLUSTERED INDEX IX_periods_active_filtered ON academico.academic_periods (is_active) INCLUDE (name, start_date, end_date) WHERE deleted_at IS NULL;

PRINT '>>> MEDICION FASE DESPUES...';
EXEC optimizacion.usp_MeasureQuery 'Q1_MatriculaDetallada', @q1, '%MARKER_Q1%', 'DESPUES';
EXEC optimizacion.usp_MeasureQuery 'Q2_ComisionesPromotor', @q2, '%MARKER_Q2%', 'DESPUES';
EXEC optimizacion.usp_MeasureQuery 'Q3_SeriesPorPeriodo', @q3, '%MARKER_Q3%', 'DESPUES';
EXEC optimizacion.usp_MeasureQuery 'Q4_EstudiantesMatriculados', @q4, '%MARKER_Q4%', 'DESPUES';
EXEC optimizacion.usp_MeasureQuery 'Q5_PorSedeYCarrera', @q5, '%MARKER_Q5%', 'DESPUES';
GO

/* ============================================================
   4. COMPARATIVA FINAL (evidencia documentada)
   ============================================================ */
PRINT '';
PRINT '=== COMPARATIVA ANTES / DESPUES (evidencia) ===';
SELECT
    query_name,
    MAX(CASE WHEN index_phase = 'ANTES' THEN elapsed_ms END)     AS antes_ms,
    MAX(CASE WHEN index_phase = 'DESPUES' THEN elapsed_ms END)   AS despues_ms,
    MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END)  AS antes_lecturas,
    MAX(CASE WHEN index_phase = 'DESPUES' THEN logical_reads END) AS despues_lecturas,
    CASE
        WHEN MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END) > 0
        THEN CAST(
            (MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END)
             - MAX(CASE WHEN index_phase = 'DESPUES' THEN logical_reads END)) * 100.0
            / MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END) AS DECIMAL(6,2))
        ELSE 0
    END AS mejora_lecturas_pct
FROM optimizacion.performance_results
GROUP BY query_name
ORDER BY query_name;
GO

PRINT 'Pruebas comparativas de rendimiento del Sprint 3 completadas.';
PRINT 'Evidencia persistida en optimizacion.performance_results.';
GO