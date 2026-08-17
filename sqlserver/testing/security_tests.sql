/* ============================================================
   SCRIPT DE TESTING - 02: PRUEBAS DE SEGURIDAD POR ROL
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Valida la matriz de permisos (GRANT/DENY/REVOKE) usando
   EXECUTE AS USER para verificar que cada perfil SOLO puede
   ejecutar las operaciones autorizadas:

   | Operacion                          | Promotor | Coordinador | Admin |
   |------------------------------------|----------|-------------|-------|
   | SELECT vw_Matriculas               | SI       | SI          | SI    |
   | SELECT operaciones.students        | SI       | SI          | SI    |
   | EXEC usp_RegistrarMatricula        | SI       | SI          | SI    |
   | SELECT seguridad.users             | NO       | NO          | SI    |
   | SELECT auditoria.audit_logs        | NO       | SI          | SI    |
   | SELECT vw_EstudiantesMatriculados  | NO       | SI          | SI    |
   | DELETE operaciones.enrollments     | NO       | NO          | SI    |
   | EXEC usp_RegistrarEstudiante       | NO       | SI          | SI    |
   ============================================================ */

USE MatriculaCloud360;
GO

/* Preparar matricula de prueba para los tests de DELETE */
IF NOT EXISTS (SELECT 1 FROM operaciones.enrollments WHERE enrollment_code = 'MAT-SEC-001')
BEGIN
    INSERT INTO operaciones.enrollments (enrollment_code, student_id, career_id, branch_id,
                                         promoter_id, period_id, campaign_id, amount)
    VALUES ('MAT-SEC-001', 1, 1, 1, 1, 1, 1, 4500.00);
END
GO

/* ============================================================
   ROL PROMOTOR
   ============================================================ */

/* S1. Promotor: SELECT vw_Matriculas -> PERMITIDO */
DECLARE @ok BIT, @detail VARCHAR(500);
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    SELECT TOP 1 * FROM dbo.vw_Matriculas;
    SET @ok = 1; SET @detail = 'Acceso permitido (esperado).';
END TRY
BEGIN CATCH
    SET @ok = 0; SET @detail = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S1 Promotor: SELECT vw_Matriculas', 'SEGURIDAD', @ok, @detail;
GO

/* S2. Promotor: SELECT operaciones.students -> PERMITIDO */
DECLARE @ok2 BIT, @detail2 VARCHAR(500);
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    SELECT TOP 1 id, dni FROM operaciones.students;
    SET @ok2 = 1; SET @detail2 = 'Acceso permitido (esperado).';
END TRY
BEGIN CATCH
    SET @ok2 = 0; SET @detail2 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S2 Promotor: SELECT estudiantes', 'SEGURIDAD', @ok2, @detail2;
GO

/* S3. Promotor: EXEC usp_RegistrarMatricula -> PERMITIDO */
DECLARE @ok3 BIT, @detail3 VARCHAR(500);
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM operaciones.enrollments WHERE enrollment_code = 'MAT-SEC-002')
    BEGIN
        EXEC dbo.usp_RegistrarMatricula 'MAT-SEC-002', 1, 1, 1, 1, 1, 1, 4500.00;
        SET @ok3 = 1; SET @detail3 = 'Matricula registrada (esperado).';
    END
    ELSE
    BEGIN
        SET @ok3 = 1; SET @detail3 = 'Matricula ya existia (ok).';
    END
END TRY
BEGIN CATCH
    SET @ok3 = 0; SET @detail3 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S3 Promotor: EXEC usp_RegistrarMatricula', 'SEGURIDAD', @ok3, @detail3;
GO

/* S4. Promotor: SELECT seguridad.users -> DENEGADO */
DECLARE @ok4 BIT, @detail4 VARCHAR(500);
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    SELECT TOP 1 * FROM seguridad.users;
    SET @ok4 = 0; SET @detail4 = 'Se permitio el acceso (NO esperado).';
END TRY
BEGIN CATCH
    SET @ok4 = 1; SET @detail4 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S4 Promotor: SELECT seguridad DENEGADO', 'SEGURIDAD', @ok4, @detail4;
GO

/* S5. Promotor: SELECT auditoria.audit_logs -> DENEGADO */
DECLARE @ok5 BIT, @detail5 VARCHAR(500);
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    SELECT TOP 1 * FROM auditoria.audit_logs;
    SET @ok5 = 0; SET @detail5 = 'Se permitio el acceso (NO esperado).';
END TRY
BEGIN CATCH
    SET @ok5 = 1; SET @detail5 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S5 Promotor: SELECT auditoria DENEGADO', 'SEGURIDAD', @ok5, @detail5;
GO

/* S6. Promotor: SELECT vw_EstudiantesMatriculados -> DENEGADO */
DECLARE @ok6 BIT, @detail6 VARCHAR(500);
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    SELECT TOP 1 * FROM dbo.vw_EstudiantesMatriculados;
    SET @ok6 = 0; SET @detail6 = 'Se permitio el acceso (NO esperado).';
END TRY
BEGIN CATCH
    SET @ok6 = 1; SET @detail6 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S6 Promotor: vw_EstudiantesMatriculados DENEGADO', 'SEGURIDAD', @ok6, @detail6;
GO

/* S7. Promotor: DELETE operaciones.students -> DENEGADO */
DECLARE @ok7 BIT, @detail7 VARCHAR(500);
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    DELETE FROM operaciones.students WHERE dni = '99999999';
    SET @ok7 = 0; SET @detail7 = 'Se permitio el DELETE (NO esperado).';
END TRY
BEGIN CATCH
    SET @ok7 = 1; SET @detail7 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S7 Promotor: DELETE estudiantes DENEGADO', 'SEGURIDAD', @ok7, @detail7;
GO

/* ============================================================
   ROL COORDINADOR ACADEMICO
   ============================================================ */

/* S8. Coordinador: SELECT vw_EstudiantesMatriculados -> PERMITIDO */
DECLARE @ok8 BIT, @detail8 VARCHAR(500);
EXECUTE AS USER = 'usuario_coordinador';
BEGIN TRY
    SELECT TOP 1 * FROM dbo.vw_EstudiantesMatriculados;
    SET @ok8 = 1; SET @detail8 = 'Acceso permitido (esperado).';
END TRY
BEGIN CATCH
    SET @ok8 = 0; SET @detail8 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S8 Coordinador: vw_EstudiantesMatriculados', 'SEGURIDAD', @ok8, @detail8;
GO

/* S9. Coordinador: SELECT auditoria.audit_logs -> PERMITIDO */
DECLARE @ok9 BIT, @detail9 VARCHAR(500);
EXECUTE AS USER = 'usuario_coordinador';
BEGIN TRY
    SELECT TOP 1 * FROM auditoria.audit_logs;
    SET @ok9 = 1; SET @detail9 = 'Acceso permitido (esperado).';
END TRY
BEGIN CATCH
    SET @ok9 = 0; SET @detail9 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S9 Coordinador: SELECT auditoria', 'SEGURIDAD', @ok9, @detail9;
GO

/* S10. Coordinador: SELECT seguridad.users -> DENEGADO */
DECLARE @ok10 BIT, @detail10 VARCHAR(500);
EXECUTE AS USER = 'usuario_coordinador';
BEGIN TRY
    SELECT TOP 1 * FROM seguridad.users;
    SET @ok10 = 0; SET @detail10 = 'Se permitio el acceso (NO esperado).';
END TRY
BEGIN CATCH
    SET @ok10 = 1; SET @detail10 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S10 Coordinador: SELECT seguridad DENEGADO', 'SEGURIDAD', @ok10, @detail10;
GO

/* S11. Coordinador: DELETE operaciones.enrollments -> DENEGADO */
DECLARE @ok11 BIT, @detail11 VARCHAR(500);
EXECUTE AS USER = 'usuario_coordinador';
BEGIN TRY
    DELETE FROM operaciones.enrollments WHERE enrollment_code = 'MAT-SEC-001';
    SET @ok11 = 0; SET @detail11 = 'Se permitio el DELETE (NO esperado).';
END TRY
BEGIN CATCH
    SET @ok11 = 1; SET @detail11 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S11 Coordinador: DELETE matriculas DENEGADO', 'SEGURIDAD', @ok11, @detail11;
GO

/* S12. Coordinador: EXEC usp_RegistrarEstudiante -> PERMITIDO */
DECLARE @ok12 BIT, @detail12 VARCHAR(500);
EXECUTE AS USER = 'usuario_coordinador';
BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '99990003')
    BEGIN
        EXEC dbo.usp_RegistrarEstudiante '99990003', 'Coordinador', 'Crea', 'coord.crea@gmail.com', '999444555';
        SET @ok12 = 1; SET @detail12 = 'Estudiante registrado (esperado).';
    END
    ELSE
    BEGIN
        SET @ok12 = 1; SET @detail12 = 'Estudiante ya existia (ok).';
    END
END TRY
BEGIN CATCH
    SET @ok12 = 0; SET @detail12 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S12 Coordinador: EXEC usp_RegistrarEstudiante', 'SEGURIDAD', @ok12, @detail12;
GO

/* ============================================================
   ROL ADMINISTRADOR
   ============================================================ */

/* S13. Administrador: SELECT seguridad.users -> PERMITIDO */
DECLARE @ok13 BIT, @detail13 VARCHAR(500);
EXECUTE AS USER = 'usuario_admin';
BEGIN TRY
    SELECT TOP 1 * FROM seguridad.users;
    SET @ok13 = 1; SET @detail13 = 'Acceso permitido (esperado).';
END TRY
BEGIN CATCH
    SET @ok13 = 0; SET @detail13 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S13 Admin: SELECT seguridad', 'SEGURIDAD', @ok13, @detail13;
GO

/* S14. Administrador: DELETE operaciones.enrollments -> PERMITIDO */
DECLARE @ok14 BIT, @detail14 VARCHAR(500);
EXECUTE AS USER = 'usuario_admin';
BEGIN TRY
    DELETE FROM operaciones.enrollments WHERE enrollment_code = 'MAT-SEC-001';
    SET @ok14 = 1; SET @detail14 = 'Matricula eliminada (esperado).';
END TRY
BEGIN CATCH
    SET @ok14 = 0; SET @detail14 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S14 Admin: DELETE matriculas', 'SEGURIDAD', @ok14, @detail14;
GO

/* S15. Administrador: EXEC usp_RegistrarEstudiante -> PERMITIDO */
DECLARE @ok15 BIT, @detail15 VARCHAR(500);
EXECUTE AS USER = 'usuario_admin';
BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '99990004')
    BEGIN
        EXEC dbo.usp_RegistrarEstudiante '99990004', 'Admin', 'Crea', 'admin.crea@gmail.com', '999666777';
        SET @ok15 = 1; SET @detail15 = 'Estudiante registrado (esperado).';
    END
    ELSE
    BEGIN
        SET @ok15 = 1; SET @detail15 = 'Estudiante ya existia (ok).';
    END
END TRY
BEGIN CATCH
    SET @ok15 = 0; SET @detail15 = LEFT(ERROR_MESSAGE(), 400);
END CATCH
REVERT;
EXEC testing.usp_RecordTest 'S15 Admin: EXEC usp_RegistrarEstudiante', 'SEGURIDAD', @ok15, @detail15;
GO

/* LIMPIEZA: eliminar la matricula de prueba creada por el promotor */
DELETE FROM operaciones.enrollments WHERE enrollment_code IN ('MAT-SEC-001', 'MAT-SEC-002');
GO

/* RESUMEN DE PRUEBAS DE SEGURIDAD */
SELECT
    result,
    COUNT(*) AS total
FROM testing.test_results
WHERE category = 'SEGURIDAD'
GROUP BY result;
GO

PRINT 'Pruebas de seguridad del Sprint 3 completadas.';
GO