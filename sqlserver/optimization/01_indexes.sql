/* ============================================================
   SCRIPT DE OPTIMIZACION - 01: INDICES
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Indices disenados a partir del analisis de las consultas
   seleccionadas en optimization/02_advanced_queries.sql:
     - Q1 (vw_Matriculas / matricula detallada): JOINs por FK
     - Q2 (comisiones por promotor/campana): promoter_id + campaign_id
     - Q3 (series temporales por periodo): enrollment_date
     - Q4 (vw_EstudiantesMatriculados): student_id + INCLUDE
     - Q5 (matriculas por sede/carrera): branch_id, career_id
     - Consultas de vigencia: filtros por deleted_at / is_active
   ============================================================ */

USE MatriculaCloud360;
GO

/* QUOTED_IDENTIFIER ON es requerido para los indices filtrados */
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   INDICES SOBRE operaciones.enrollments (tabla transaccional)
   ============================================================ */

-- 1. FK student_id: JOIN de Q1 y Q4 (busqueda por estudiante)
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_student_id'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_student_id
    ON operaciones.enrollments (student_id);
    PRINT 'Creado IX_enrollments_student_id';
END
GO

-- 2. FK career_id: filtros y agrupaciones por carrera
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_career_id'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_career_id
    ON operaciones.enrollments (career_id);
    PRINT 'Creado IX_enrollments_career_id';
END
GO

-- 3. FK branch_id: analisis por sede
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_branch_id'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_branch_id
    ON operaciones.enrollments (branch_id);
    PRINT 'Creado IX_enrollments_branch_id';
END
GO

-- 4. FK promoter_id + campaign_id + INCLUDE (amount):
--    soporta Q2 (comisiones por promotor/campana) sin tocar la tabla
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_promoter_campaign_cover'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_promoter_campaign_cover
    ON operaciones.enrollments (promoter_id, campaign_id)
    INCLUDE (student_id, branch_id, period_id, amount);
    PRINT 'Creado IX_enrollments_promoter_campaign_cover';
END
GO

-- 5. FK period_id: consultas por periodo academico
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_period_id'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_period_id
    ON operaciones.enrollments (period_id);
    PRINT 'Creado IX_enrollments_period_id';
END
GO

-- 6. FK campaign_id: consultas por campana de admision
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_campaign_id'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_campaign_id
    ON operaciones.enrollments (campaign_id);
    PRINT 'Creado IX_enrollments_campaign_id';
END
GO

-- 7. enrollment_date: series temporales (Q3) y rangos de fecha
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_enrollment_date'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_enrollment_date
    ON operaciones.enrollments (enrollment_date);
    PRINT 'Creado IX_enrollments_enrollment_date';
END
GO

-- 8. Indice de cobertura para Q4 (vw_EstudiantesMatriculados):
--    COUNT y SUM por student_id sin regresar a la tabla (covering index)
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_enrollments_student_cover'
                 AND object_id = OBJECT_ID('operaciones.enrollments'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_enrollments_student_cover
    ON operaciones.enrollments (student_id)
    INCLUDE (amount, enrollment_date);
    PRINT 'Creado IX_enrollments_student_cover';
END
GO

/* ============================================================
   INDICES SOBRE operaciones.students
   ============================================================ */

-- 9. Indice filtrado (filtered index): listados de estudiantes
--    activos, donde la vista y los procedimientos filtran deleted_at IS NULL
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_students_active_filtered'
                 AND object_id = OBJECT_ID('operaciones.students'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_students_active_filtered
    ON operaciones.students (last_name, first_name)
    INCLUDE (dni, personal_email, phone)
    WHERE deleted_at IS NULL;
    PRINT 'Creado IX_students_active_filtered';
END
GO

/* ============================================================
   INDICES SOBRE operaciones.promoters
   ============================================================ */

-- 10. base_branch_id: validacion promotor-sede (usp_RegistrarMatricula)
--     y consultas de promotores por sede
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_promoters_base_branch'
                 AND object_id = OBJECT_ID('operaciones.promoters'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_promoters_base_branch
    ON operaciones.promoters (base_branch_id);
    PRINT 'Creado IX_promoters_base_branch';
END
GO

/* ============================================================
   INDICES SOBRE catalogos (academico)
   ============================================================ */

-- 11. admission_campaigns: busqueda de campanas activas (Q5 y usp)
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_campaigns_active_filtered'
                 AND object_id = OBJECT_ID('academico.admission_campaigns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_campaigns_active_filtered
    ON academico.admission_campaigns (is_active)
    INCLUDE (name, commission_percentage)
    WHERE deleted_at IS NULL;
    PRINT 'Creado IX_campaigns_active_filtered';
END
GO

-- 12. academic_periods: busqueda de periodos activos
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_periods_active_filtered'
                 AND object_id = OBJECT_ID('academico.academic_periods'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_periods_active_filtered
    ON academico.academic_periods (is_active)
    INCLUDE (name, start_date, end_date)
    WHERE deleted_at IS NULL;
    PRINT 'Creado IX_periods_active_filtered';
END
GO

PRINT 'Estrategia de indices del Sprint 3 aplicada correctamente.';
GO