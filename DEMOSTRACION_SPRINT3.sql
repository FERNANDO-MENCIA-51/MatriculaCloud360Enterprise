/* DEMOSTRACION SPRINT 3 - version corregida para grabacion */
/* Ejecutar en orden sobre MatriculaCloud360 con sa */

USE MatriculaCloud360;
GO

/* 1. Inventario de 18 triggers */
PRINT '1. TRIGGERS (18)';
SELECT OBJECT_SCHEMA_NAME(parent_id) AS esquema,
       OBJECT_NAME(parent_id) AS tabla,
       name AS trigger_
FROM sys.triggers
ORDER BY tabla;
GO

/* 2. Auditoria INSERT/UPDATE/DELETE */
PRINT '2. AUDITORIA';
INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
VALUES ('80008001', 'Demo', 'Auditoria', 'demo.audit@video.com', '911000111');
GO

DECLARE @sid INT = (SELECT id FROM operaciones.students WHERE dni = '80008001');
UPDATE operaciones.students SET phone = '911000112' WHERE id = @sid;
DELETE FROM operaciones.students WHERE id = @sid;
GO

/* 3. Bitacora generada */
PRINT '3. BITACORA';
SELECT id, operation, executed_by, action_date
FROM auditoria.audit_logs
WHERE table_name = 'operaciones.students'
ORDER BY id DESC;
GO

/* 4. Soft-delete sobre branches */
PRINT '4. SOFT-DELETE';
DELETE FROM academico.branches WHERE id = 4;
GO

SELECT id, code, name, deleted_at FROM academico.branches WHERE id = 4;
GO

/* 5. Auditoria del soft-delete (mostramos cualquier auditoria reciente) */
PRINT '5. AUDITORIA SOFT-DELETE';
SELECT TOP 3 id, table_name, operation, executed_by, action_date
FROM auditoria.audit_logs
ORDER BY id DESC;
GO

/* 6. Restaurar sede */
UPDATE academico.branches SET deleted_at = NULL WHERE id = 4;
PRINT '6. SEDE RESTAURADA';
GO

/* 7. Indicadores institucionales */
PRINT '7. INDICADORES INSTITUCIONALES';
SELECT
    (SELECT COUNT(*) FROM operaciones.students WHERE deleted_at IS NULL) AS total_estudiantes,
    (SELECT COUNT(*) FROM operaciones.enrollments) AS total_matriculas,
    (SELECT COUNT(*) FROM academico.careers WHERE deleted_at IS NULL) AS total_carreras,
    (SELECT COUNT(*) FROM academico.branches WHERE deleted_at IS NULL) AS total_sedes,
    SUM(amount) AS ingreso_total,
    AVG(amount) AS ticket_promedio
FROM operaciones.enrollments;
GO

/* 8. Comisiones por promotor con RANK */
PRINT '8. COMISIONES POR PROMOTOR (RANK)';
SELECT p.full_name AS promoter,
       COUNT(e.id) AS total_matriculas,
       SUM(e.amount * ac.commission_percentage / 100.0) AS comision_total,
       RANK() OVER (ORDER BY SUM(e.amount * ac.commission_percentage / 100.0) DESC) AS ranking
FROM operaciones.enrollments e
INNER JOIN operaciones.promoters p ON e.promoter_id = p.id
INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id
GROUP BY p.full_name;
GO

/* 9. Serie temporal con LAG */
PRINT '9. SERIE TEMPORAL (LAG)';
SELECT ap.name AS periodo,
       COUNT(e.id) AS matriculas,
       LAG(COUNT(e.id), 1, 0) OVER (ORDER BY ap.id) AS periodo_anterior
FROM operaciones.enrollments e
INNER JOIN academico.academic_periods ap ON e.period_id = ap.id
GROUP BY ap.id, ap.name;
GO

/* 10. Subconsulta correlacionada */
PRINT '10. SUBCONSULTA CORRELACIONADA';
SELECT e.enrollment_code,
       c.name AS carrera,
       e.amount,
       (SELECT AVG(e2.amount) FROM operaciones.enrollments e2 WHERE e2.career_id = e.career_id) AS promedio_carrera
FROM operaciones.enrollments e
INNER JOIN academico.careers c ON e.career_id = c.id;
GO

/* 11. CPU acumulado por consulta */
PRINT '11. CPU ACUMULADO';
SELECT TOP 5
    SUBSTRING(t.text, 1, 80) AS consulta,
    qs.total_worker_time / 1000 AS cpu_ms
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
WHERE t.text LIKE '%MARKER_Q%'
ORDER BY qs.total_worker_time DESC;
GO

/* 12. Seguridad: Promotor (puede) */
PRINT '12. PROMOTOR: PUEDE';
EXECUTE AS USER = 'usuario_promotor';
GO

SELECT TOP 3 enrollment_code, amount FROM dbo.vw_Matriculas;
EXEC dbo.usp_RegistrarMatricula
    @enrollment_code = 'MAT-DEMO-001', @student_id = 1, @career_id = 1,
    @branch_id = 1, @promoter_id = 1, @period_id = 1, @campaign_id = 1, @amount = 5000.00;
PRINT 'OK: matricula registrada por promotor';
GO

/* 13. Seguridad: Promotor (denegado) */
BEGIN TRY
    SELECT * FROM seguridad.users;
    PRINT 'FALLO: acceso permitido';
END TRY
BEGIN CATCH
    PRINT 'DENEGADO: ' + ERROR_MESSAGE();
END CATCH;
GO

REVERT;
GO

/* 14. Seguridad: Coordinador */
PRINT '14. COORDINADOR';
EXECUTE AS USER = 'usuario_coordinador';
GO

SELECT TOP 3 * FROM dbo.vw_EstudiantesMatriculados;
PRINT 'OK: vista institucional visible';

BEGIN TRY
    DELETE FROM operaciones.enrollments WHERE enrollment_code = 'MAT-10001';
    PRINT 'FALLO: acceso permitido';
END TRY
BEGIN CATCH
    PRINT 'DENEGADO: ' + ERROR_MESSAGE();
END CATCH;
GO

REVERT;
GO

/* 15. Seguridad: Administrador */
PRINT '15. ADMINISTRADOR';
EXECUTE AS USER = 'usuario_admin';
GO

SELECT TOP 3 username FROM seguridad.users;
PRINT 'OK: credenciales visibles';

DELETE FROM operaciones.enrollments WHERE enrollment_code = 'MAT-DEMO-001';
PRINT 'OK: administrador elimino matricula';
GO

REVERT;
GO

/* 16. Respaldo FULL */
PRINT '16. RESPALDO FULL';
EXEC dbo.usp_BackupDatabaseFull;
GO

/* 17. Bitacora mantenimiento */
PRINT '17. BITACORA MANTENIMIENTO';
SELECT TOP 3 object_name, operation, run_date FROM auditoria.maintenance_log ORDER BY id DESC;
GO

/* 18. Integridad */
PRINT '18. INTEGRIDAD';
EXEC dbo.usp_CheckDatabaseIntegrity;
GO

/* 19. Respaldos generados */
PRINT '19. RESPALDOS';
SELECT database_name, type, backup_finish_date
FROM msdb.dbo.backupset
WHERE database_name = 'MatriculaCloud360'
ORDER BY backup_finish_date DESC;
GO

/* 20. Simulacion perdida y restauracion */
PRINT '20. SIMULACION PERDIDA Y RESTAURACION';
INSERT INTO operaciones.students (dni, first_name, last_name, personal_email)
VALUES ('80009999', 'Marcador', 'Restore', 'marcador.restore@video.com');
GO

PRINT 'Marcador presente:';
SELECT dni FROM operaciones.students WHERE dni = '80009999';
GO

EXEC dbo.usp_RestoreDatabaseFull;
GO

/* 21. Pruebas integrales (ejecutar despues de reconectar) */
PRINT '21. PRUEBAS INTEGRALES (ejecutar despues de reconectar)';
SELECT category AS suite,
       COUNT(*) AS pruebas,
       SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS pasaron
FROM testing.test_results
GROUP BY category;
GO
