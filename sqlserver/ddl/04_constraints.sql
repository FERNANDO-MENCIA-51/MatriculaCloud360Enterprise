/* SCRIPT DDL - 04: Restricciones CHECK Adicionales */

USE MatriculaCloud360;
GO


-- 1. CK_enrollments_amount: El monto de matricula debe ser positivo

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE OBJECT_NAME(parent_object_id) = 'enrollments'
                 AND SCHEMA_NAME(schema_id) = 'operaciones'
                 AND name = 'CK_enrollments_amount')
BEGIN
    ALTER TABLE operaciones.enrollments
    ADD CONSTRAINT CK_enrollments_amount CHECK (amount > 0);
END
GO


-- 2. CK_admission_campaigns_commission: Comision entre 0% y 100%

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE OBJECT_NAME(parent_object_id) = 'admission_campaigns'
                 AND SCHEMA_NAME(schema_id) = 'academico'
                 AND name = 'CK_admission_campaigns_commission_percentage')
BEGIN
    ALTER TABLE academico.admission_campaigns
    ADD CONSTRAINT CK_admission_campaigns_commission_percentage
    CHECK (commission_percentage BETWEEN 0 AND 100);
END
GO

-- 3. CK_academic_periods_end_date: La fecha fin debe ser posterior al inicio

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE OBJECT_NAME(parent_object_id) = 'academic_periods'
                 AND SCHEMA_NAME(schema_id) = 'academico'
                 AND name = 'CK_academic_periods_end_date')
BEGIN
    ALTER TABLE academico.academic_periods
    ADD CONSTRAINT CK_academic_periods_end_date CHECK (end_date > start_date);
END
GO


-- 4. CK_enrollments_enrollment_date: La fecha de matricula no puede ser futura

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE OBJECT_NAME(parent_object_id) = 'enrollments'
                 AND SCHEMA_NAME(schema_id) = 'operaciones'
                 AND name = 'CK_enrollments_enrollment_date')
BEGIN
    ALTER TABLE operaciones.enrollments
    ADD CONSTRAINT CK_enrollments_enrollment_date CHECK (enrollment_date <= GETDATE());
END
GO


-- 5. CK_courses_credits: Los creditos deben estar entre 1 y 30

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE OBJECT_NAME(parent_object_id) = 'courses'
                 AND SCHEMA_NAME(schema_id) = 'academico'
                 AND name = 'CK_courses_credits')
BEGIN
    ALTER TABLE academico.courses
    ADD CONSTRAINT CK_courses_credits CHECK (credits BETWEEN 1 AND 30);
END
GO


-- 6. CK_careers_duration_cycles: La duracion debe estar entre 1 y 12 ciclos

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE OBJECT_NAME(parent_object_id) = 'careers'
                 AND SCHEMA_NAME(schema_id) = 'academico'
                 AND name = 'CK_careers_duration_cycles')
BEGIN
    ALTER TABLE academico.careers
    ADD CONSTRAINT CK_careers_duration_cycles CHECK (duration_cycles BETWEEN 1 AND 12);
END
GO


-- 7. CK_careers_total_investment: La inversion total debe ser positiva

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE OBJECT_NAME(parent_object_id) = 'careers'
                 AND SCHEMA_NAME(schema_id) = 'academico'
                 AND name = 'CK_careers_total_investment')
BEGIN
    ALTER TABLE academico.careers
    ADD CONSTRAINT CK_careers_total_investment CHECK (total_investment > 0);
END
GO

PRINT 'Restricciones CHECK del Sprint 2 aplicadas correctamente.';
GO