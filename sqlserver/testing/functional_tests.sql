/* ============================================================
   SCRIPT DE TESTING - 01: PRUEBAS FUNCIONALES INTEGRALES
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Valida el funcionamiento conjunto de:
     - Procedimientos almacenados (Sprint 2)
     - Triggers de auditoria y soft-delete (Sprint 3)
     - Vistas, funcion de comision y consultas analiticas
   Cada prueba registra PASS/FAIL en testing.test_results.
   ============================================================ */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* 1. ESQUEMA Y TABLA DE RESULTADOS */
IF SCHEMA_ID('testing') IS NULL
    EXEC('CREATE SCHEMA testing');
GO

IF OBJECT_ID('testing.test_results', N'U') IS NULL
BEGIN
    CREATE TABLE testing.test_results (
        id INT IDENTITY(1,1) PRIMARY KEY,
        test_name VARCHAR(150) NOT NULL,
        category VARCHAR(50) NOT NULL,
        result VARCHAR(10) NOT NULL,
        detail VARCHAR(500) NULL,
        run_date DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

/* 2. PROCEDIMIENTO AUXILIAR DE REGISTRO */
CREATE OR ALTER PROCEDURE testing.usp_RecordTest
    @test_name VARCHAR(150),
    @category VARCHAR(50),
    @passed BIT,
    @detail VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO testing.test_results (test_name, category, result, detail)
    VALUES (@test_name, @category, CASE WHEN @passed = 1 THEN 'PASS' ELSE 'FAIL' END, @detail);
END
GO

/* 3. LIMPIEZA DE DATOS DE PRUEBAS ANTERIORES */
DELETE FROM testing.test_results;
DELETE FROM operaciones.enrollments WHERE enrollment_code LIKE 'MAT-TEST%';
UPDATE operaciones.students SET deleted_at = NULL WHERE dni LIKE '9999%';

/* Estudiante "vivo" dedicado a las pruebas de matricula (nunca se elimina) */
IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '99990005')
BEGIN
    INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
    VALUES ('99990005', 'Vivo', 'Matricula', 'vivo.matricula@gmail.com', '999000111');
END
GO

/* ============================================================
   TESTS FUNCIONALES
   ============================================================ */

/* T1. Registrar estudiante valido */
IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '99990001')
BEGIN
    BEGIN TRY
        CREATE TABLE #t_new_id (new_id INT);
        INSERT INTO #t_new_id EXEC dbo.usp_RegistrarEstudiante
            '99990001', 'Prueba', 'Sprint3', 'prueba.sprint3@gmail.com', '999111222';

        IF EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '99990001')
            EXEC testing.usp_RecordTest 'T1 Registrar estudiante', 'FUNCIONAL', 1, 'Estudiante registrado correctamente.';
        ELSE
            EXEC testing.usp_RecordTest 'T1 Registrar estudiante', 'FUNCIONAL', 0, 'No se encontro el estudiante registrado.';

        DROP TABLE #t_new_id;
    END TRY
    BEGIN CATCH
        DECLARE @err_msg VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
        EXEC testing.usp_RecordTest 'T1 Registrar estudiante', 'FUNCIONAL', 0, @err_msg;
    END CATCH
END
ELSE
BEGIN
    EXEC testing.usp_RecordTest 'T1 Registrar estudiante', 'FUNCIONAL', 1, 'Ya registrado en corrida anterior (ok).';
END
GO

/* T2. Rechazar DNI duplicado */
BEGIN TRY
    EXEC dbo.usp_RegistrarEstudiante '75112233', 'Duplicado', 'DNI', 'dup.dni@gmail.com';
    EXEC testing.usp_RecordTest 'T2 DNI duplicado rechazado', 'FUNCIONAL', 0, 'Se permitio registrar un DNI duplicado.';
END TRY
BEGIN CATCH
    DECLARE @err_msg2 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T2 DNI duplicado rechazado', 'FUNCIONAL', 1, @err_msg2;
END CATCH
GO

/* T3. Rechazar email duplicado */
BEGIN TRY
    EXEC dbo.usp_RegistrarEstudiante '77778888', 'Duplicado', 'Email', 'ana.perez@gmail.com';
    EXEC testing.usp_RecordTest 'T3 Email duplicado rechazado', 'FUNCIONAL', 0, 'Se permitio registrar un email duplicado.';
END TRY
BEGIN CATCH
    DECLARE @err_msg3 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T3 Email duplicado rechazado', 'FUNCIONAL', 1, @err_msg3;
END CATCH
GO

/* T4. Actualizar estudiante */
BEGIN TRY
    DECLARE @stu_id INT = (SELECT id FROM operaciones.students WHERE dni = '99990001');
    EXEC dbo.usp_ActualizarEstudiante @stu_id, 'Prueba', 'Sprint3 Actualizado', 'prueba.sprint3@gmail.com', '999111222';

    IF EXISTS (SELECT 1 FROM operaciones.students WHERE id = @stu_id AND last_name = 'Sprint3 Actualizado')
        EXEC testing.usp_RecordTest 'T4 Actualizar estudiante', 'FUNCIONAL', 1, 'Estudiante actualizado.';
    ELSE
        EXEC testing.usp_RecordTest 'T4 Actualizar estudiante', 'FUNCIONAL', 0, 'La actualizacion no se aplico.';
END TRY
BEGIN CATCH
    DECLARE @err_msg4 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T4 Actualizar estudiante', 'FUNCIONAL', 0, @err_msg4;
END CATCH
GO

/* T5. Soft-delete via procedimiento (deleted_at) */
BEGIN TRY
    DECLARE @stu_id2 INT = (SELECT id FROM operaciones.students WHERE dni = '99990001');
    EXEC dbo.usp_EliminarEstudiante @stu_id2;

    IF EXISTS (SELECT 1 FROM operaciones.students WHERE id = @stu_id2 AND deleted_at IS NOT NULL)
        EXEC testing.usp_RecordTest 'T5 Soft-delete via procedimiento', 'FUNCIONAL', 1, 'deleted_at registrado; el registro persiste.';
    ELSE
        EXEC testing.usp_RecordTest 'T5 Soft-delete via procedimiento', 'FUNCIONAL', 0, 'El registro fue eliminado fisicamente o no se marco.';
END TRY
BEGIN CATCH
    DECLARE @err_msg5 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T5 Soft-delete via procedimiento', 'FUNCIONAL', 0, @err_msg5;
END CATCH
GO

/* T6. DELETE fisico convertido a soft-delete por trigger */
IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '99990002')
BEGIN
    INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
    VALUES ('99990002', 'Fisico', 'Delete', 'fisico.delete@gmail.com', '999333444');
END

DELETE FROM operaciones.students WHERE dni = '99990002';

IF EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '99990002' AND deleted_at IS NOT NULL)
    EXEC testing.usp_RecordTest 'T6 DELETE fisico -> soft-delete', 'FUNCIONAL', 1, 'Trigger INSTEAD OF DELETE aplico borrado logico.';
ELSE
    EXEC testing.usp_RecordTest 'T6 DELETE fisico -> soft-delete', 'FUNCIONAL', 0, 'El registro se elimino fisicamente.';
GO

/* T7. Trigger de auditoria: INSERT, UPDATE, DELETE generan registros */
BEGIN TRY
    DECLARE @aud_id INT = (SELECT id FROM operaciones.students WHERE dni = '99990001');
    DECLARE @cnt_insert INT = (SELECT COUNT(*) FROM auditoria.audit_logs
                               WHERE table_name = 'operaciones.students' AND operation = 'INSERT' AND record_id = @aud_id);
    DECLARE @cnt_update INT = (SELECT COUNT(*) FROM auditoria.audit_logs
                               WHERE table_name = 'operaciones.students' AND operation = 'UPDATE' AND record_id = @aud_id);
    DECLARE @cnt_delete INT = (SELECT COUNT(*) FROM auditoria.audit_logs
                               WHERE table_name = 'operaciones.students' AND operation = 'DELETE' AND record_id = @aud_id);
    DECLARE @det7 VARCHAR(500);

    IF @cnt_insert >= 1 AND @cnt_update >= 1 AND @cnt_delete >= 1
    BEGIN
        SET @det7 = 'Auditoria generada: I=' + CAST(@cnt_insert AS VARCHAR(10)) +
                    ', U=' + CAST(@cnt_update AS VARCHAR(10)) +
                    ', D=' + CAST(@cnt_delete AS VARCHAR(10));
        EXEC testing.usp_RecordTest 'T7 Auditoria INSERT/UPDATE/DELETE', 'AUDITORIA', 1, @det7;
    END
    ELSE
    BEGIN
        SET @det7 = 'Faltan registros de auditoria (I=' + CAST(@cnt_insert AS VARCHAR(10)) +
                    ', U=' + CAST(@cnt_update AS VARCHAR(10)) +
                    ', D=' + CAST(@cnt_delete AS VARCHAR(10)) + ').';
        EXEC testing.usp_RecordTest 'T7 Auditoria INSERT/UPDATE/DELETE', 'AUDITORIA', 0, @det7;
    END
END TRY
BEGIN CATCH
    DECLARE @err_msg7 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T7 Auditoria INSERT/UPDATE/DELETE', 'AUDITORIA', 0, @err_msg7;
END CATCH
GO

/* T8. Registrar matricula valida (con auditoria) */
BEGIN TRY
    DECLARE @est_id INT = (SELECT TOP 1 id FROM operaciones.students WHERE dni = '99990005');

    IF NOT EXISTS (SELECT 1 FROM operaciones.enrollments WHERE enrollment_code = 'MAT-TEST-001')
    BEGIN
        EXEC dbo.usp_RegistrarMatricula
            'MAT-TEST-001', @est_id, 1, 1, 1, 1, 1, 4500.00;

        IF EXISTS (SELECT 1 FROM operaciones.enrollments WHERE enrollment_code = 'MAT-TEST-001')
            EXEC testing.usp_RecordTest 'T8 Registrar matricula valida', 'FUNCIONAL', 1, 'Matricula MAT-TEST-001 registrada.';
        ELSE
            EXEC testing.usp_RecordTest 'T8 Registrar matricula valida', 'FUNCIONAL', 0, 'La matricula no se registro.';
    END
    ELSE
    BEGIN
        EXEC testing.usp_RecordTest 'T8 Registrar matricula valida', 'FUNCIONAL', 1, 'Ya registrada en corrida anterior (ok).';
    END
END TRY
BEGIN CATCH
    DECLARE @err_msg8 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T8 Registrar matricula valida', 'FUNCIONAL', 0, @err_msg8;
END CATCH
GO

/* T9. Rechazar matricula con promotor de otra sede */
BEGIN TRY
    DECLARE @est_id9 INT = (SELECT TOP 1 id FROM operaciones.students WHERE dni = '99990005');
    EXEC dbo.usp_RegistrarMatricula 'MAT-TEST-009', @est_id9, 1, 3, 1, 1, 1, 4500.00;
    EXEC testing.usp_RecordTest 'T9 Promotor de otra sede rechazado', 'FUNCIONAL', 0, 'Se permitio matricular con promotor de otra sede.';
END TRY
BEGIN CATCH
    DECLARE @err_msg9 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T9 Promotor de otra sede rechazado', 'FUNCIONAL', 1, @err_msg9;
END CATCH
GO

/* T10. Rechazar matricula con periodo inactivo */
IF NOT EXISTS (SELECT 1 FROM academico.academic_periods WHERE name = 'TEST-INACTIVO')
BEGIN
    INSERT INTO academico.academic_periods (name, start_date, end_date, is_active)
    VALUES ('TEST-INACTIVO', '2030-01-01', '2030-12-31', 0);
END
GO

BEGIN TRY
    DECLARE @est_id10 INT = (SELECT TOP 1 id FROM operaciones.students WHERE dni = '99990005');
    DECLARE @per_inactivo INT = (SELECT id FROM academico.academic_periods WHERE name = 'TEST-INACTIVO');
    EXEC dbo.usp_RegistrarMatricula 'MAT-TEST-010', @est_id10, 1, 1, 1, @per_inactivo, 1, 4500.00;
    EXEC testing.usp_RecordTest 'T10 Periodo inactivo rechazado', 'FUNCIONAL', 0, 'Se permitio matricular en periodo inactivo.';
END TRY
BEGIN CATCH
    DECLARE @err_msg10 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T10 Periodo inactivo rechazado', 'FUNCIONAL', 1, @err_msg10;
END CATCH
GO

/* T11. Rechazar matricula con monto <= 0 */
BEGIN TRY
    DECLARE @est_id11 INT = (SELECT TOP 1 id FROM operaciones.students WHERE dni = '99990005');
    EXEC dbo.usp_RegistrarMatricula 'MAT-TEST-011', @est_id11, 1, 1, 1, 1, 1, 0.00;
    EXEC testing.usp_RecordTest 'T11 Monto <= 0 rechazado', 'FUNCIONAL', 0, 'Se permitio matricula con monto cero.';
END TRY
BEGIN CATCH
    DECLARE @err_msg11 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T11 Monto <= 0 rechazado', 'FUNCIONAL', 1, @err_msg11;
END CATCH
GO

/* T12. Obtener detalle de matricula */
BEGIN TRY
    CREATE TABLE #t_enc2 (id INT, enrollment_code VARCHAR(20), student VARCHAR(200), career VARCHAR(100),
                          branch VARCHAR(100), promoter VARCHAR(150), period VARCHAR(20),
                          campaign VARCHAR(100), amount DECIMAL(10,2), commission DECIMAL(10,2), enrollment_date DATETIME);
    INSERT INTO #t_enc2 EXEC dbo.usp_ObtenerMatricula @enrollment_code = 'MAT-10001';

    IF EXISTS (SELECT 1 FROM #t_enc2)
        EXEC testing.usp_RecordTest 'T12 Obtener detalle de matricula', 'FUNCIONAL', 1, 'Detalle obtenido para MAT-10001.';
    ELSE
        EXEC testing.usp_RecordTest 'T12 Obtener detalle de matricula', 'FUNCIONAL', 0, 'No se obtuvo detalle.';

    DROP TABLE #t_enc2;
END TRY
BEGIN CATCH
    DECLARE @err_msg12 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T12 Obtener detalle de matricula', 'FUNCIONAL', 0, @err_msg12;
END CATCH
GO

/* T13. Listar estudiantes excluye eliminados */
BEGIN TRY
    CREATE TABLE #t_lista (id INT, dni VARCHAR(15), first_name VARCHAR(100), last_name VARCHAR(100),
                           personal_email VARCHAR(100), phone VARCHAR(20));
    INSERT INTO #t_lista EXEC dbo.usp_ListarEstudiantes;

    IF NOT EXISTS (SELECT 1 FROM #t_lista WHERE dni = '99990001')
        EXEC testing.usp_RecordTest 'T13 Listar excluye eliminados', 'FUNCIONAL', 1, 'El estudiante soft-deleted no aparece.';
    ELSE
        EXEC testing.usp_RecordTest 'T13 Listar excluye eliminados', 'FUNCIONAL', 0, 'Aparece un estudiante eliminado.';

    DROP TABLE #t_lista;
END TRY
BEGIN CATCH
    DECLARE @err_msg13 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T13 Listar excluye eliminados', 'FUNCIONAL', 0, @err_msg13;
END CATCH
GO

/* T14. Funcion de comision correcta (MAT-10001: 4500 * 5% = 225) */
BEGIN TRY
    DECLARE @comision DECIMAL(10,2) = dbo.fn_CalcularComision(
        (SELECT id FROM operaciones.enrollments WHERE enrollment_code = 'MAT-10001'));
    DECLARE @det14 VARCHAR(500);

    IF @comision = 225.00
    BEGIN
        SET @det14 = 'Comision calculada: ' + CAST(@comision AS VARCHAR(20));
        EXEC testing.usp_RecordTest 'T14 fn_CalcularComision', 'FUNCIONAL', 1, @det14;
    END
    ELSE
    BEGIN
        SET @det14 = 'Comision inesperada: ' + CAST(@comision AS VARCHAR(20));
        EXEC testing.usp_RecordTest 'T14 fn_CalcularComision', 'FUNCIONAL', 0, @det14;
    END
END TRY
BEGIN CATCH
    DECLARE @err_msg14 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T14 fn_CalcularComision', 'FUNCIONAL', 0, @err_msg14;
END CATCH
GO

/* T15. Vistas operativas */
BEGIN TRY
    DECLARE @v1 INT = (SELECT COUNT(*) FROM dbo.vw_Matriculas);
    DECLARE @v2 INT = (SELECT COUNT(*) FROM dbo.vw_EstudiantesMatriculados);
    DECLARE @det15 VARCHAR(500);

    IF @v1 > 0 AND @v2 > 0
    BEGIN
        SET @det15 = 'vw_Matriculas=' + CAST(@v1 AS VARCHAR(10)) + ', vw_Estudiantes=' + CAST(@v2 AS VARCHAR(10));
        EXEC testing.usp_RecordTest 'T15 Vistas operativas', 'FUNCIONAL', 1, @det15;
    END
    ELSE
    BEGIN
        EXEC testing.usp_RecordTest 'T15 Vistas operativas', 'FUNCIONAL', 0, 'Vistas sin datos.';
    END
END TRY
BEGIN CATCH
    DECLARE @err_msg15 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T15 Vistas operativas', 'FUNCIONAL', 0, @err_msg15;
END CATCH
GO

/* T16. Consultas analiticas (CTE, ventana, agregados) */
BEGIN TRY
    ;WITH KPIs AS (
        SELECT COUNT(*) AS total FROM operaciones.enrollments
    )
    SELECT * FROM KPIs;

    ;WITH Comisiones AS (
        SELECT p.full_name, SUM(e.amount * ac.commission_percentage / 100.0) AS comision
        FROM operaciones.enrollments e
        INNER JOIN operaciones.promoters p ON e.promoter_id = p.id
        INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id
        GROUP BY p.full_name
    )
    SELECT * FROM Comisiones;

    SELECT enrollment_code, amount,
           AVG(amount) OVER (ORDER BY id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS movil
    FROM operaciones.enrollments;

    SELECT COUNT(*) FROM dbo.vw_Matriculas;

    EXEC testing.usp_RecordTest 'T16 Consultas analiticas', 'ANALITICO', 1, 'CTE, ventana y agregados ejecutados sin errores.';
END TRY
BEGIN CATCH
    DECLARE @err_msg16 VARCHAR(500) = LEFT(ERROR_MESSAGE(), 480);
    EXEC testing.usp_RecordTest 'T16 Consultas analiticas', 'ANALITICO', 0, @err_msg16;
END CATCH
GO

/* T17. Soft-delete en catalogos (academico.branches) */
IF NOT EXISTS (SELECT 1 FROM academico.branches WHERE code = 'SED-TEST')
BEGIN
    INSERT INTO academico.branches (code, name, city)
    VALUES ('SED-TEST', 'Sede de Prueba', 'Chincha');
END

DELETE FROM academico.branches WHERE code = 'SED-TEST';

IF EXISTS (SELECT 1 FROM academico.branches WHERE code = 'SED-TEST' AND deleted_at IS NOT NULL)
    EXEC testing.usp_RecordTest 'T17 Soft-delete catalogos', 'FUNCIONAL', 1, 'La sede quedo como borrado logico.';
ELSE
    EXEC testing.usp_RecordTest 'T17 Soft-delete catalogos', 'FUNCIONAL', 0, 'La sede se elimino fisicamente.';
GO

/* 4. RESUMEN DE PRUEBAS */
SELECT
    category,
    COUNT(*) AS total,
    SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END) AS failed
FROM testing.test_results
GROUP BY category
ORDER BY category;
GO

PRINT 'Pruebas funcionales del Sprint 3 completadas.';
GO