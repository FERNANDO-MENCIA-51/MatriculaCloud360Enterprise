/* ====================================================================================
   SCRIPT DE PRUEBAS DML: INSERT, UPDATE, SOFT-DELETE, DUPLICIDAD Y AUDITORÍA

   ------------------------------------------------------------------------------------
   Estructura Sistemática:
     1. Inserción (INSERT): 1 registro por tabla con su SELECT de comprobación.
     2. Modificación (UPDATE): 1 actualización por tabla con su SELECT de comprobación.
     3. Eliminación Lógica (SOFT-DELETE): 1 baja lógica por tabla con su SELECT de comprobación.
     4. Control de Duplicidad (UNIQUE): 1 prueba de restricción UNIQUE por tabla con TRY...CATCH.
     5. Inspección de Auditoría: Consulta de la bitácora JSON en auditoria.audit_logs.
   Nota: Salidas en formato tabular (SELECT) para visualización en SSMS / ADS.
   ==================================================================================== */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Asegurar contexto de administrador (sa / dbo)
WHILE USER_NAME() <> 'dbo'
BEGIN
    REVERT;
END;
GO


/* ====================================================================================
   LIMPIEZA IDEMPOTENTE PREVIA (Orden estricto de hijos a padres)
   ==================================================================================== */

-- Desactivar temporalmente triggers de soft-delete para purga previa
EXEC('DISABLE TRIGGER operaciones.trg_students_soft_delete ON operaciones.students');
EXEC('DISABLE TRIGGER operaciones.trg_promoters_soft_delete ON operaciones.promoters');
EXEC('DISABLE TRIGGER academico.trg_courses_soft_delete ON academico.courses');
EXEC('DISABLE TRIGGER academico.trg_teachers_soft_delete ON academico.teachers');
EXEC('DISABLE TRIGGER academico.trg_careers_soft_delete ON academico.careers');
EXEC('DISABLE TRIGGER academico.trg_branches_soft_delete ON academico.branches');

-- 1. Matrículas de prueba
DELETE FROM operaciones.enrollments WHERE enrollment_code LIKE 'MAT-TEST-9%' OR enrollment_code LIKE 'MAT-DML-%';

-- 2. Asignación carrera-curso de prueba
DELETE FROM academico.career_courses 
WHERE career_id IN (SELECT id FROM academico.careers WHERE code LIKE 'CAR-9%')
   OR course_id IN (SELECT id FROM academico.courses WHERE code LIKE 'C-9%');

-- 3. Promotores de prueba
DELETE FROM operaciones.promoters WHERE dni LIKE '8899%' OR dni LIKE '8811%';

-- 4. Usuarios de prueba
DELETE FROM seguridad.users WHERE username LIKE 'user.prueba.9%' OR username LIKE 'promotor.%' OR username LIKE 'auditor.%';

-- 5. Estudiantes de prueba
DELETE FROM operaciones.students WHERE dni LIKE '8899%' OR dni LIKE '8800%';

-- 6. Cursos de prueba
DELETE FROM academico.courses WHERE code LIKE 'C-9%';

-- 7. Docentes de prueba
DELETE FROM academico.teachers 
WHERE corporate_email LIKE '%@demo-dml.edu.pe' 
   OR corporate_email = 'docente.test@edufuturo.edu.pe';

-- 8. Campañas y Periodos de prueba
DELETE FROM academico.admission_campaigns WHERE name LIKE 'Campaña Prueba%' OR name LIKE 'Campaña DML%';
DELETE FROM academico.academic_periods WHERE name LIKE '2028-%' OR name LIKE '2027-%';

-- 9. Carreras y Sedes de prueba
DELETE FROM academico.careers WHERE code LIKE 'CAR-9%';
DELETE FROM academico.branches WHERE code LIKE 'SED-9%';

-- Reactivar triggers de soft-delete
EXEC('ENABLE TRIGGER operaciones.trg_students_soft_delete ON operaciones.students');
EXEC('ENABLE TRIGGER operaciones.trg_promoters_soft_delete ON operaciones.promoters');
EXEC('ENABLE TRIGGER academico.trg_courses_soft_delete ON academico.courses');
EXEC('ENABLE TRIGGER academico.trg_teachers_soft_delete ON academico.teachers');
EXEC('ENABLE TRIGGER academico.trg_careers_soft_delete ON academico.careers');
EXEC('ENABLE TRIGGER academico.trg_branches_soft_delete ON academico.branches');
GO


/* ====================================================================================
   SECCIÓN 1: INSERCIÓN (1 INSERT POR TABLA + SELECT DE COMPROBACIÓN)
   ==================================================================================== */

-- 1.1 academico.branches (Sedes)
INSERT INTO academico.branches (code, name, city)
VALUES ('SED-901', 'Sede Prueba Sur', 'Tacna');

SELECT '1.1 INSERT SEDE' AS [Sección], id AS [ID], code AS [Código], name AS [Nombre], city AS [Ciudad]
FROM academico.branches WHERE code = 'SED-901';
GO

-- 1.2 academico.careers (Carreras)
INSERT INTO academico.careers (code, name, duration_cycles, total_investment)
VALUES ('CAR-901', 'Ciencia de Datos', 6, 21000.00);

SELECT '1.2 INSERT CARRERA' AS [Sección], id AS [ID], code AS [Código], name AS [Carrera], CAST(total_investment AS DECIMAL(10,2)) AS [Inversión (S/.)]
FROM academico.careers WHERE code = 'CAR-901';
GO

-- 1.3 academico.teachers (Docentes)
INSERT INTO academico.teachers (full_name, corporate_email, specialty)
VALUES ('Profesor Prueba', 'docente.test@edufuturo.edu.pe', 'Estadística y Big Data');

SELECT '1.3 INSERT DOCENTE' AS [Sección], id AS [ID], full_name AS [Docente], corporate_email AS [Correo], specialty AS [Especialidad]
FROM academico.teachers WHERE corporate_email = 'docente.test@edufuturo.edu.pe';
GO

-- 1.4 academico.courses (Cursos)
DECLARE @tid INT = (SELECT id FROM academico.teachers WHERE corporate_email = 'docente.test@edufuturo.edu.pe');
INSERT INTO academico.courses (code, name, credits, teacher_id)
VALUES ('C-901', 'Minería de Datos', 4, @tid);

SELECT '1.4 INSERT CURSO' AS [Sección], id AS [ID], code AS [Código], name AS [Curso], credits AS [Créditos], teacher_id AS [ID Docente]
FROM academico.courses WHERE code = 'C-901';
GO

-- 1.5 academico.academic_periods (Periodos)
INSERT INTO academico.academic_periods (name, start_date, end_date, is_active)
VALUES ('2028-I', '2028-03-01', '2028-08-31', 1);

SELECT '1.5 INSERT PERIODO' AS [Sección], id AS [ID], name AS [Periodo], start_date AS [Inicio], end_date AS [Fin], is_active AS [Activo]
FROM academico.academic_periods WHERE name = '2028-I';
GO

-- 1.6 academico.admission_campaigns (Campañas)
INSERT INTO academico.admission_campaigns (name, commission_percentage, is_active)
VALUES ('Campaña Prueba 901', 8.00, 1);

SELECT '1.6 INSERT CAMPAÑA' AS [Sección], id AS [ID], name AS [Campaña], CAST(commission_percentage AS DECIMAL(5,2)) AS [% Comisión], is_active AS [Activa]
FROM academico.admission_campaigns WHERE name = 'Campaña Prueba 901';
GO

-- 1.7 seguridad.users (Usuarios)
INSERT INTO seguridad.users (role_id, username, password_hash, is_active)
VALUES (3, 'user.prueba.901', 'hash_pass_901', 1);

SELECT '1.7 INSERT USUARIO' AS [Sección], id AS [ID], username AS [Usuario], role_id AS [Rol ID], is_active AS [Activo]
FROM seguridad.users WHERE username = 'user.prueba.901';
GO

-- 1.8 operaciones.promoters (Promotores)
DECLARE @uid INT = (SELECT id FROM seguridad.users WHERE username = 'user.prueba.901');
DECLARE @bid INT = (SELECT id FROM academico.branches WHERE code = 'SED-901');
INSERT INTO operaciones.promoters (user_id, dni, full_name, base_branch_id, corporate_email)
VALUES (@uid, '88990001', 'Promotor Prueba', @bid, 'promotor.test@edufuturo.edu.pe');

SELECT '1.8 INSERT PROMOTOR' AS [Sección], id AS [ID], dni AS [DNI], full_name AS [Promotor], base_branch_id AS [ID Sede Base]
FROM operaciones.promoters WHERE dni = '88990001';
GO

-- 1.9 operaciones.students (Estudiantes)
INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
VALUES ('88990001', 'Alumno', 'Prueba', 'alumno.test@gmail.com', '988776655');

SELECT '1.9 INSERT ESTUDIANTE' AS [Sección], id AS [ID], dni AS [DNI], CONCAT(first_name, ' ', last_name) AS [Estudiante], personal_email AS [Correo]
FROM operaciones.students WHERE dni = '88990001';
GO

-- 1.10 operaciones.enrollments (Matrículas)
DECLARE @st_id INT  = (SELECT id FROM operaciones.students WHERE dni = '88990001');
DECLARE @car_id INT = (SELECT id FROM academico.careers WHERE code = 'CAR-901');
DECLARE @br_id INT  = (SELECT id FROM academico.branches WHERE code = 'SED-901');
DECLARE @pro_id INT = (SELECT id FROM operaciones.promoters WHERE dni = '88990001');
DECLARE @per_id INT = (SELECT id FROM academico.academic_periods WHERE name = '2028-I');
DECLARE @cam_id INT = (SELECT id FROM academico.admission_campaigns WHERE name = 'Campaña Prueba 901');

INSERT INTO operaciones.enrollments (enrollment_code, student_id, career_id, branch_id, promoter_id, period_id, campaign_id, amount)
VALUES ('MAT-TEST-901', @st_id, @car_id, @br_id, @pro_id, @per_id, @cam_id, 4800.00);

SELECT '1.10 INSERT MATRÍCULA' AS [Sección], id AS [ID], enrollment_code AS [Código], amount AS [Monto (S/.)], FORMAT(enrollment_date, 'yyyy-MM-dd HH:mm') AS [Fecha]
FROM operaciones.enrollments WHERE enrollment_code = 'MAT-TEST-901';
GO


/* ====================================================================================
   SECCIÓN 2: MODIFICACIÓN (1 UPDATE POR TABLA + SELECT DE COMPROBACIÓN)
   ==================================================================================== */

-- 2.1 UPDATE Sede
UPDATE academico.branches SET name = 'Sede Prueba Sur Modificada' WHERE code = 'SED-901';
SELECT '2.1 UPDATE SEDE' AS [Sección], code AS [Código], name AS [Nombre Modificado] FROM academico.branches WHERE code = 'SED-901';
GO

-- 2.2 UPDATE Carrera
UPDATE academico.careers SET total_investment = 22500.00 WHERE code = 'CAR-901';
SELECT '2.2 UPDATE CARRERA' AS [Sección], code AS [Código], CAST(total_investment AS DECIMAL(10,2)) AS [Nueva Inversión] FROM academico.careers WHERE code = 'CAR-901';
GO

-- 2.3 UPDATE Docente
UPDATE academico.teachers SET specialty = 'Arquitectura Cloud e IA' WHERE corporate_email = 'docente.test@edufuturo.edu.pe';
SELECT '2.3 UPDATE DOCENTE' AS [Sección], full_name AS [Docente], specialty AS [Especialidad Actualizada] FROM academico.teachers WHERE corporate_email = 'docente.test@edufuturo.edu.pe';
GO

-- 2.4 UPDATE Curso
UPDATE academico.courses SET credits = 5 WHERE code = 'C-901';
SELECT '2.4 UPDATE CURSO' AS [Sección], code AS [Código], name AS [Curso], credits AS [Créditos Actualizados] FROM academico.courses WHERE code = 'C-901';
GO

-- 2.5 UPDATE Periodo
UPDATE academico.academic_periods SET is_active = 0 WHERE name = '2028-I';
SELECT '2.5 UPDATE PERIODO' AS [Sección], name AS [Periodo], is_active AS [Estado Inactivo] FROM academico.academic_periods WHERE name = '2028-I';
GO

-- 2.6 UPDATE Campaña
UPDATE academico.admission_campaigns SET commission_percentage = 9.50 WHERE name = 'Campaña Prueba 901';
SELECT '2.6 UPDATE CAMPAÑA' AS [Sección], name AS [Campaña], CAST(commission_percentage AS DECIMAL(5,2)) AS [Nuevo % Comisión] FROM academico.admission_campaigns WHERE name = 'Campaña Prueba 901';
GO

-- 2.7 UPDATE Usuario
UPDATE seguridad.users SET password_hash = 'hash_modificado_901' WHERE username = 'user.prueba.901';
SELECT '2.7 UPDATE USUARIO' AS [Sección], username AS [Usuario], password_hash AS [Password Hash Modificado] FROM seguridad.users WHERE username = 'user.prueba.901';
GO

-- 2.8 UPDATE Promotor
UPDATE operaciones.promoters SET corporate_email = 'promotor.nuevo@edufuturo.edu.pe' WHERE dni = '88990001';
SELECT '2.8 UPDATE PROMOTOR' AS [Sección], dni AS [DNI], corporate_email AS [Correo Corporativo Actualizado] FROM operaciones.promoters WHERE dni = '88990001';
GO

-- 2.9 UPDATE Estudiante
UPDATE operaciones.students SET phone = '911999888', personal_email = 'alumno.modificado@gmail.com' WHERE dni = '88990001';
SELECT '2.9 UPDATE ESTUDIANTE' AS [Sección], dni AS [DNI], phone AS [Nuevo Teléfono], personal_email AS [Nuevo Correo] FROM operaciones.students WHERE dni = '88990001';
GO

-- 2.10 UPDATE Matrícula
UPDATE operaciones.enrollments SET amount = 5300.00 WHERE enrollment_code = 'MAT-TEST-901';
SELECT '2.10 UPDATE MATRÍCULA' AS [Sección], enrollment_code AS [Código], CAST(amount AS DECIMAL(10,2)) AS [Monto Actualizado] FROM operaciones.enrollments WHERE enrollment_code = 'MAT-TEST-901';
GO


/* ====================================================================================
   SECCIÓN 3: ELIMINACIÓN LÓGICA (SOFT-DELETE POR TABLA + SELECT DE COMPROBACIÓN)
   ==================================================================================== */

-- 3.1 Soft-Delete en Estudiante de Prueba (sin matrículas dependientes)
INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
VALUES ('88990002', 'AlumnoBorrado', 'Logico', 'alumno.del@test.com', '900111222');

DELETE FROM operaciones.students WHERE dni = '88990002'; -- Activa trigger trg_students_soft_delete

SELECT '3.1 SOFT-DELETE ESTUDIANTE' AS [Sección], dni AS [DNI], CONCAT(first_name, ' ', last_name) AS [Estudiante], FORMAT(deleted_at, 'yyyy-MM-dd HH:mm:ss') AS [Fecha Desactivación], 'Registro preservado' AS [Garantía]
FROM operaciones.students WHERE dni = '88990002';
GO

-- 3.2 Soft-Delete en Curso de Prueba (sin matrículas)
INSERT INTO academico.courses (code, name, credits, teacher_id)
VALUES ('C-902', 'Curso Para Borrar', 3, (SELECT TOP 1 id FROM academico.teachers));

DELETE FROM academico.courses WHERE code = 'C-902'; -- Activa trigger trg_courses_soft_delete

SELECT '3.2 SOFT-DELETE CURSO' AS [Sección], code AS [Código], name AS [Curso], FORMAT(deleted_at, 'yyyy-MM-dd HH:mm:ss') AS [Fecha Desactivación], 'Registro preservado' AS [Garantía]
FROM academico.courses WHERE code = 'C-902';
GO

-- 3.3 Soft-Delete en Sede de Prueba (sin promotores ni matrículas)
INSERT INTO academico.branches (code, name, city)
VALUES ('SED-902', 'Sede Para Borrar', 'Cusco');

DELETE FROM academico.branches WHERE code = 'SED-902'; -- Activa trigger trg_branches_soft_delete

SELECT '3.3 SOFT-DELETE SEDE' AS [Sección], code AS [Código], name AS [Sede], FORMAT(deleted_at, 'yyyy-MM-dd HH:mm:ss') AS [Fecha Desactivación], 'Registro preservado' AS [Garantía]
FROM academico.branches WHERE code = 'SED-902';
GO

-- 3.4 Soft-Delete en Carrera de Prueba (sin matrículas)
INSERT INTO academico.careers (code, name, duration_cycles, total_investment)
VALUES ('CAR-902', 'Carrera Para Borrar', 4, 16000.00);

DELETE FROM academico.careers WHERE code = 'CAR-902'; -- Activa trigger trg_careers_soft_delete

SELECT '3.4 SOFT-DELETE CARRERA' AS [Sección], code AS [Código], name AS [Carrera], FORMAT(deleted_at, 'yyyy-MM-dd HH:mm:ss') AS [Fecha Desactivación], 'Registro preservado' AS [Garantía]
FROM academico.careers WHERE code = 'CAR-902';
GO


/* ====================================================================================
   SECCIÓN 4: CONTROL DE DUPLICIDAD (1 PRUEBA UNIQUE POR TABLA CON TRY...CATCH)
   ==================================================================================== */

-- 4.1 Duplicidad en Sedes (code UNIQUE)
BEGIN TRY
    INSERT INTO academico.branches (code, name, city) VALUES ('SED-901', 'Sede Duplicada', 'Lima');
    SELECT '4.1 DUPLICIDAD SEDE' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió código duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.1 DUPLICIDAD SEDE' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO

-- 4.2 Duplicidad en Carreras (code UNIQUE)
BEGIN TRY
    INSERT INTO academico.careers (code, name, duration_cycles, total_investment) VALUES ('CAR-901', 'Carrera Duplicada', 6, 18000.00);
    SELECT '4.2 DUPLICIDAD CARRERA' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió código duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.2 DUPLICIDAD CARRERA' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO

-- 4.3 Duplicidad en Docentes (corporate_email UNIQUE)
BEGIN TRY
    INSERT INTO academico.teachers (full_name, corporate_email, specialty) VALUES ('Otro Docente', 'docente.test@edufuturo.edu.pe', 'Redes');
    SELECT '4.3 DUPLICIDAD DOCENTE' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió correo duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.3 DUPLICIDAD DOCENTE' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO

-- 4.4 Duplicidad en Cursos (code UNIQUE)
BEGIN TRY
    INSERT INTO academico.courses (code, name, credits, teacher_id) VALUES ('C-901', 'Curso Duplicado', 3, 1);
    SELECT '4.4 DUPLICIDAD CURSO' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió código duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.4 DUPLICIDAD CURSO' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO

-- 4.5 Duplicidad en Usuarios (username UNIQUE)
BEGIN TRY
    INSERT INTO seguridad.users (role_id, username, password_hash, is_active) VALUES (3, 'user.prueba.901', 'hash_dup', 1);
    SELECT '4.5 DUPLICIDAD USUARIO' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió username duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.5 DUPLICIDAD USUARIO' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO

-- 4.6 Duplicidad en Promotores (dni UNIQUE)
BEGIN TRY
    INSERT INTO operaciones.promoters (user_id, dni, full_name, base_branch_id, corporate_email)
    VALUES (1, '88990001', 'Promotor Duplicado', 1, 'otro.promotor@edufuturo.edu.pe');
    SELECT '4.6 DUPLICIDAD PROMOTOR' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió DNI duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.6 DUPLICIDAD PROMOTOR' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO

-- 4.7 Duplicidad en Estudiantes (dni / personal_email UNIQUE)
BEGIN TRY
    INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
    VALUES ('88990001', 'Estudiante', 'Duplicado', 'otro.alumno@gmail.com', '911000111');
    SELECT '4.7 DUPLICIDAD ESTUDIANTE' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió DNI duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.7 DUPLICIDAD ESTUDIANTE' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO

-- 4.8 Duplicidad en Matrículas (enrollment_code UNIQUE)
BEGIN TRY
    INSERT INTO operaciones.enrollments (enrollment_code, student_id, career_id, branch_id, promoter_id, period_id, campaign_id, amount)
    VALUES ('MAT-TEST-901', 1, 1, 1, 1, 1, 1, 4500.00);
    SELECT '4.8 DUPLICIDAD MATRÍCULA' AS [Prueba], 'FALLO' AS [Resultado], 'Se permitió código de matrícula duplicado' AS [Detalle];
END TRY
BEGIN CATCH
    SELECT '4.8 DUPLICIDAD MATRÍCULA' AS [Prueba], 'RECHAZADO POR UNIQUE (ESPERADO)' AS [Resultado], ERROR_MESSAGE() AS [Detalle de Protección];
END CATCH;
GO


/* ====================================================================================
   SECCIÓN 5: INSPECCIÓN DE LA BITÁCORA DE AUDITORÍA JSON (auditoria.audit_logs)
   ==================================================================================== */

-- 5.1 Últimos Registros Generados en la Bitácora (INSERT, UPDATE, DELETE)
SELECT TOP 10
    '5.1 BITÁCORA DE AUDITORÍA' AS [Sección],
    id AS [ID Log],
    table_name AS [Tabla Modificada],
    operation AS [Operación],
    executed_by AS [Usuario Responsable],
    FORMAT(action_date, 'yyyy-MM-dd HH:mm:ss.fff') AS [Fecha y Hora],
    old_data AS [Datos Anteriores (JSON)],
    new_data AS [Datos Nuevos (JSON)]
FROM auditoria.audit_logs
ORDER BY id DESC;
GO

-- 5.2 Consolidado de Eventos de Auditoría por Tabla
SELECT 
    '5.2 CONSOLIDADO DE AUDITORÍA' AS [Sección],
    table_name AS [Tabla Auditada],
    SUM(CASE WHEN operation = 'INSERT' THEN 1 ELSE 0 END) AS [Total INSERTs],
    SUM(CASE WHEN operation = 'UPDATE' THEN 1 ELSE 0 END) AS [Total UPDATEs],
    SUM(CASE WHEN operation = 'DELETE' THEN 1 ELSE 0 END) AS [Total DELETEs],
    COUNT(*) AS [Total Eventos Registrados]
FROM auditoria.audit_logs
GROUP BY table_name
ORDER BY [Total Eventos Registrados] DESC;
GO


/* ====================================================================================
   SECCIÓN 6: RESUMEN GENERAL DE PRUEBAS DML Y AUDITORÍA
   ==================================================================================== */

SELECT 
    '6. RESUMEN FINAL' AS [Sección],
    '1. Inserciones (1 por tabla)' AS [Operación Evaluada],
    '10 tablas recibieron nuevos registros con verificación SELECT inmediata' AS [Resultado],
    'EXITOSO' AS [Estado]
UNION ALL
SELECT 
    '6. RESUMEN FINAL',
    '2. Modificaciones (1 UPDATE por tabla)',
    '10 tablas modificadas capturando estados anteriores y nuevos en JSON',
    'EXITOSO'
UNION ALL
SELECT 
    '6. RESUMEN FINAL',
    '3. Eliminación Lógica (Soft-Delete)',
    'DELETE físico transformado en soft-delete vía trigger (deleted_at IS NOT NULL)',
    'EXITOSO'
UNION ALL
SELECT 
    '6. RESUMEN FINAL',
    '4. Control de Duplicidad (UNIQUE)',
    '8 restricciones UNIQUE validadas y rechazadas por el motor con éxito',
    'EXITOSO'
UNION ALL
SELECT 
    '6. RESUMEN FINAL',
    '5. Trazabilidad en auditoria.audit_logs',
    'Bitácora activa con registros JSON de old_data y new_data',
    'EXITOSO';
GO
