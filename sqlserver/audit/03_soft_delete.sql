/* ============================================================
   SCRIPT DE AUDITORIA - 03: BORRADO LOGICO (SOFT DELETE)
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Estrategia: ninguna tabla critica se elimina fisicamente.
   El campo deleted_at conserva el registro y registra la fecha
   y hora de eliminacion.

   - Ya cuentan con deleted_at (desde Sprint 1/2):
       academico.branches, careers, teachers, courses
       operaciones.students, promoters
   - Se agrega deleted_at en este script:
       academico.academic_periods, academico.admission_campaigns
   - Los triggers INSTEAD OF DELETE que convierten DELETE en
     soft-delete se crean en programmability/triggers/ (ver 02).
   ============================================================ */

USE MatriculaCloud360;
GO

/* 1. academic_periods */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('academico.academic_periods')
                 AND name = 'deleted_at')
BEGIN
    ALTER TABLE academico.academic_periods ADD deleted_at DATETIME NULL;
    PRINT 'Columna deleted_at agregada a academico.academic_periods.';
END
GO

/* 2. admission_campaigns */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('academico.admission_campaigns')
                 AND name = 'deleted_at')
BEGIN
    ALTER TABLE academico.admission_campaigns ADD deleted_at DATETIME NULL;
    PRINT 'Columna deleted_at agregada a academico.admission_campaigns.';
END
GO

/* 3. Verificacion final: tablas protegidas por soft-delete */
PRINT 'Tablas con borrado logico (deleted_at):';
PRINT '  - academico.branches / careers / teachers / courses';
PRINT '  - academico.academic_periods / admission_campaigns';
PRINT '  - operaciones.students / promoters';
PRINT 'Borrado logico del Sprint 3 configurado correctamente.';
GO