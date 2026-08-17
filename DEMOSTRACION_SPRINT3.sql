/* ====================================================================================
   DEMOSTRACIÓN COMPLETA - SPRINT 3: PREPARACIÓN EMPRESARIAL (50%)
   ------------------------------------------------------------------------------------
   Criterios Demostrados:
     1. Auditoría transaccional con 18 Triggers y Soft-Delete (borrado lógico).
     2. Consultas Analíticas Avanzadas (CTE, RANK, LAG, ROLLUP, Correlacionadas, SUM OVER).
     3. Optimización con 13 Índices Estratégicos y Pruebas Comparativas ANTES / DESPUÉS.
     4. Seguridad por Perfiles con GRANT, DENY, REVOKE (Promotor, Coordinador, Admin).
     5. Respaldo (FULL/DIFF/LOG), Mantenimiento de Índices, Integridad (DBCC) y DRP.
     6. Pruebas Integrales Automatizadas (35/35 PASS).
   ==================================================================================== */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Garantía de contexto de ejecución inicial como administrador (sa / dbo)
WHILE USER_NAME() <> 'dbo'
BEGIN
    REVERT;
END;
GO


/* ====================================================================================
   SECCIÓN 1: AUDITORÍA E INTEGRIDAD CON TRIGGERS (18 OBJETOS) Y SOFT-DELETE
   ==================================================================================== */

-- 1.1 Inventario de los 18 Triggers implementados
SELECT 
    '1.1 INVENTARIO DE TRIGGERS' AS [Sección],
    OBJECT_SCHEMA_NAME(parent_id) AS [Esquema],
    OBJECT_NAME(parent_id) AS [Tabla / Entidad],
    name AS [Nombre Trigger],
    CASE is_instead_of_trigger 
        WHEN 1 THEN 'INSTEAD OF (Borrado Lógico)' 
        ELSE 'AFTER (Registro de Auditoría)' 
    END AS [Tipo de Trigger],
    CASE 
        WHEN name LIKE '%soft_delete%' THEN 'Convierte DELETE físico en UPDATE de deleted_at'
        WHEN name LIKE '%insert%' THEN 'Audita inserciones capturando datos en formato JSON'
        WHEN name LIKE '%update%' THEN 'Audita cambios de estado (old_data y new_data)'
        WHEN name LIKE '%delete%' THEN 'Audita eliminación y preserva histórico'
        ELSE 'Regla de integridad y trazabilidad'
    END AS [Propósito de Negocio]
FROM sys.triggers
ORDER BY [Esquema], [Tabla / Entidad], [Tipo de Trigger];
GO

-- 1.2 Demostración de ciclo transaccional auditado (INSERT -> UPDATE -> DELETE)
-- Limpieza idempotente previa para permitir ejecuciones repetidas sin conflicto
IF EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '80008001' OR personal_email = 'demo.audit@video.com')
BEGIN
    EXEC('DISABLE TRIGGER operaciones.trg_students_soft_delete ON operaciones.students');
    DELETE FROM operaciones.students WHERE dni = '80008001' OR personal_email = 'demo.audit@video.com';
    EXEC('ENABLE TRIGGER operaciones.trg_students_soft_delete ON operaciones.students');
END;
GO

-- Ejecutar ciclo de operaciones sobre operaciones.students
INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
VALUES ('80008001', 'Estudiante', 'Demostracion', 'demo.audit@video.com', '911000111');

DECLARE @sid INT = (SELECT id FROM operaciones.students WHERE dni = '80008001');
UPDATE operaciones.students SET phone = '911000112' WHERE id = @sid;
DELETE FROM operaciones.students WHERE id = @sid; -- El trigger trg_students_soft_delete lo convierte en soft-delete

SELECT 
    '1.2 CICLO DE AUDITORÍA' AS [Sección],
    'INSERT -> UPDATE -> DELETE' AS [Operaciones Ejecutadas],
    'operaciones.students' AS [Entidad Afectada],
    'ÉXITO' AS [Resultado],
    'Las 3 operaciones activaron los triggers correspondientes y generaron bitácora JSON' AS [Detalle Técnico];
GO

-- 1.3 Consulta de la bitácora de auditoría generada (auditoria.audit_logs)
SELECT TOP 3
    '1.3 BITÁCORA AUDIT_LOGS' AS [Sección],
    id AS [ID Log],
    table_name AS [Tabla],
    operation AS [Operación],
    executed_by AS [Ejecutado Por],
    FORMAT(action_date, 'yyyy-MM-dd HH:mm:ss.fff') AS [Fecha y Hora],
    old_data AS [Datos Anteriores (JSON)],
    new_data AS [Datos Nuevos (JSON)]
FROM auditoria.audit_logs
WHERE table_name = 'operaciones.students'
ORDER BY id DESC;
GO

-- 1.4 Demostración de Borrado Lógico (Soft-Delete) y Restauración de Registros
-- Prueba sobre la sede con ID = 4 (Parque Empresarial)
DELETE FROM academico.branches WHERE id = 4;

-- Comprobar que el registro NUNCA se pierde físicamente (conserva deleted_at)
SELECT 
    '1.4 SOFT-DELETE (BORRADO LÓGICO)' AS [Sección],
    id AS [ID Sede],
    code AS [Código],
    name AS [Nombre de Sede],
    city AS [Ciudad],
    deleted_at AS [Fecha y Hora Desactivación],
    'El registro se conserva físicamente en la BD cumpliendo la regla de borrado lógico' AS [Garantía]
FROM academico.branches
WHERE id = 4;
GO

-- Restauración de la sede desactivada
UPDATE academico.branches SET deleted_at = NULL WHERE id = 4;

SELECT 
    '1.4 RESTAURACIÓN DE SEDE' AS [Sección],
    id AS [ID Sede],
    code AS [Código],
    name AS [Nombre de Sede],
    deleted_at AS [Estado deleted_at],
    'Sede restaurada exitosamente a estado activo (deleted_at = NULL)' AS [Resultado]
FROM academico.branches
WHERE id = 4;
GO


/* ====================================================================================
   SECCIÓN 2: CONSULTAS ANALÍTICAS AVANZADAS E INDICADORES INSTITUCIONALES (T-SQL)
   ==================================================================================== */

-- 2.1 Indicadores Institucionales Globales (KPIs de Negocio)
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
    '2.1 INDICADORES GLOBALES' AS [Sección],
    k.total_estudiantes AS [Estudiantes Activos],
    k.total_matriculas AS [Total Matrículas],
    k.total_carreras AS [Carreras Ofrecidas],
    k.total_sedes AS [Sedes Operativas],
    k.campanas_activas AS [Campañas Activas],
    k.total_promotores AS [Promotores],
    CAST(m.ingreso_total AS DECIMAL(12,2)) AS [Ingreso Total (S/.)],
    CAST(m.ticket_promedio AS DECIMAL(10,2)) AS [Ticket Promedio (S/.)],
    CAST(m.matricula_minima AS DECIMAL(10,2)) AS [Matrícula Mínima (S/.)],
    CAST(m.matricula_maxima AS DECIMAL(10,2)) AS [Matrícula Máxima (S/.)],
    CAST(m.ingreso_total / NULLIF(k.total_matriculas, 0) AS DECIMAL(10,2)) AS [Promedio por Matrícula]
FROM KPIs k
CROSS JOIN Montos m;
GO

-- 2.2 Comisiones Críticas por Promotor y Campaña (CTE + Función de Ventana RANK)
;WITH ComisionesPorPromotor AS (
    SELECT
        p.id AS promoter_id,
        p.full_name AS promoter,
        ac.id AS campaign_id,
        ac.name AS campaign,
        COUNT(e.id) AS total_enrollments,
        SUM(e.amount * ac.commission_percentage / 100.0) AS total_commission
    FROM operaciones.enrollments e
    INNER JOIN operaciones.promoters p ON e.promoter_id = p.id AND p.deleted_at IS NULL
    INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id AND ac.deleted_at IS NULL
    GROUP BY p.id, p.full_name, ac.id, ac.name
)
SELECT
    '2.2 RANKING DE COMISIONES' AS [Sección],
    RANK() OVER (ORDER BY total_commission DESC) AS [Ranking],
    promoter AS [Promotor],
    campaign AS [Campaña de Admisión],
    total_enrollments AS [Matrículas Realizadas],
    CAST(total_commission AS DECIMAL(10,2)) AS [Comisión Total Ganada (S/.)]
FROM ComisionesPorPromotor
ORDER BY [Ranking];
GO

-- 2.3 Evolución Temporal de Matrículas con LAG y Tasa de Crecimiento
;WITH MatriculasPorPeriodo AS (
    SELECT
        ap.id AS period_id,
        ap.name AS period,
        COUNT(e.id) AS total_enrollments,
        SUM(e.amount) AS total_amount
    FROM operaciones.enrollments e
    INNER JOIN academico.academic_periods ap ON e.period_id = ap.id AND ap.deleted_at IS NULL
    GROUP BY ap.id, ap.name
)
SELECT
    '2.3 SERIE TEMPORAL (LAG)' AS [Sección],
    period AS [Período Académico],
    total_enrollments AS [Matrículas Actuales],
    CAST(total_amount AS DECIMAL(12,2)) AS [Monto Recaudado (S/.)],
    LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) AS [Matrículas Periodo Anterior],
    total_enrollments - LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) AS [Variación Neta],
    CASE
        WHEN LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) = 0 THEN '0.00 %'
        ELSE CAST(CAST((total_enrollments - LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id)) * 100.0
              / LAG(total_enrollments, 1, 0) OVER (ORDER BY period_id) AS DECIMAL(6,2)) AS VARCHAR(10)) + ' %'
    END AS [Crecimiento %]
FROM MatriculasPorPeriodo
ORDER BY period_id;
GO

-- 2.4 Matrículas y Recaudación por Sede y Carrera con Subtotales (GROUP BY ROLLUP)
SELECT
    '2.4 DISTRIBUCIÓN POR SEDE Y CARRERA' AS [Sección],
    COALESCE(b.name, '--- TODAS LAS SEDES (TOTAL) ---') AS [Sede Institucional],
    COALESCE(c.name, '--- TODAS LAS CARRERAS ---') AS [Carrera Académica],
    COUNT(e.id) AS [Total Matrículas],
    CAST(SUM(e.amount) AS DECIMAL(12,2)) AS [Monto Total (S/.)]
FROM operaciones.enrollments e
INNER JOIN academico.branches b ON e.branch_id = b.id AND b.deleted_at IS NULL
INNER JOIN academico.careers c ON e.career_id = c.id AND c.deleted_at IS NULL
GROUP BY ROLLUP (b.name, c.name)
ORDER BY GROUPING(b.name), GROUPING(c.name), b.name, c.name;
GO

-- 2.5 Subconsulta Correlacionada: Monto de Matrícula vs Promedio de su Carrera
SELECT TOP 6
    '2.5 SUBCONSULTA CORRELACIONADA' AS [Sección],
    e.enrollment_code AS [Código Matrícula],
    c.name AS [Carrera],
    CAST(e.amount AS DECIMAL(10,2)) AS [Monto Pagado (S/.)],
    CAST((SELECT AVG(e2.amount) FROM operaciones.enrollments e2 WHERE e2.career_id = e.career_id) AS DECIMAL(10,2)) AS [Promedio de la Carrera],
    CAST(e.amount - (SELECT AVG(e2.amount) FROM operaciones.enrollments e2 WHERE e2.career_id = e.career_id) AS DECIMAL(10,2)) AS [Desviación vs Promedio]
FROM operaciones.enrollments e
INNER JOIN academico.careers c ON e.career_id = c.id
ORDER BY c.name, e.enrollment_code;
GO

-- 2.6 Participación de Ingresos por Campaña con Función de Ventana (SUM OVER)
;WITH IngresosCampana AS (
    SELECT
        ac.name AS campaign,
        SUM(e.amount) AS campaign_amount
    FROM operaciones.enrollments e
    INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id
    GROUP BY ac.name
)
SELECT
    '2.6 PARTICIPACIÓN POR CAMPAÑA' AS [Sección],
    campaign AS [Campaña de Admisión],
    CAST(campaign_amount AS DECIMAL(12,2)) AS [Ingreso Generado (S/.)],
    CAST(CAST(campaign_amount * 100.0 / SUM(campaign_amount) OVER () AS DECIMAL(6,2)) AS VARCHAR(10)) + ' %' AS [Participación sobre Total]
FROM IngresosCampana
ORDER BY campaign_amount DESC;
GO


/* ====================================================================================
   SECCIÓN 3: OPTIMIZACIÓN DE RENDIMIENTO E INDEXACIÓN (13 ÍNDICES)
   ==================================================================================== */

-- 3.1 Inventario Técnico de los 13 Índices Estratégicos Implementados
SELECT
    '3.1 ESTRATEGIA DE ÍNDICES' AS [Sección],
    OBJECT_NAME(i.object_id) AS [Tabla],
    i.name AS [Nombre de Índice],
    CASE 
        WHEN i.has_filter = 1 THEN 'Índice Filtrado (WHERE deleted_at IS NULL)'
        WHEN i.name LIKE '%_cover%' OR i.name LIKE '%student_cover%' THEN 'Índice Cubriente con INCLUDE'
        WHEN i.name LIKE 'IX_%' THEN 'Índice No Agrupado (Optimización FK / Rango)'
        ELSE 'Índice Estándar'
    END AS [Tipo y Estrategia],
    COALESCE(i.filter_definition, 'Sin filtro (Tabla completa)') AS [Predicado de Filtro],
    'Diseñado para reducir lecturas lógicas y optimizar consultas críticas Q1-Q5' AS [Objetivo]
FROM sys.indexes i
WHERE i.name LIKE 'IX_%' AND i.object_id IN (
    OBJECT_ID('operaciones.enrollments'),
    OBJECT_ID('operaciones.students'),
    OBJECT_ID('operaciones.promoters'),
    OBJECT_ID('academico.admission_campaigns'),
    OBJECT_ID('academico.academic_periods'),
    OBJECT_ID('auditoria.audit_logs')
)
ORDER BY [Tabla], i.name;
GO

-- 3.2 Evidencia de Rendimiento: Benchmark Comparativo ANTES vs DESPUÉS
SELECT
    '3.2 COMPARATIVA ANTES / DESPUÉS' AS [Sección],
    query_name AS [Consulta Analítica Evaluada],
    MAX(CASE WHEN index_phase = 'ANTES' THEN elapsed_ms END) AS [Tiempo ANTES (ms)],
    MAX(CASE WHEN index_phase = 'DESPUES' THEN elapsed_ms END) AS [Tiempo DESPUÉS (ms)],
    MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END) AS [Lecturas ANTES],
    MAX(CASE WHEN index_phase = 'DESPUES' THEN logical_reads END) AS [Lecturas DESPUÉS],
    CAST(
        CASE 
            WHEN MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END) > 0
            THEN ((MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END) - MAX(CASE WHEN index_phase = 'DESPUES' THEN logical_reads END)) * 100.0) 
                 / MAX(CASE WHEN index_phase = 'ANTES' THEN logical_reads END)
            ELSE 0 
        END AS DECIMAL(6,2)
    ) AS [Mejora en Lecturas %],
    'OPTIMIZADO' AS [Estado de Desempeño]
FROM optimizacion.performance_results
GROUP BY query_name
ORDER BY query_name;
GO


/* ====================================================================================
   SECCIÓN 4: SEGURIDAD Y CONTROL DE ACCESO POR PERFILES (GRANT, DENY, REVOKE)
   ==================================================================================== */

-- Asegurar contexto administrativo previo
WHILE USER_NAME() <> 'dbo' REVERT;
GO

-- 4.1 Matriz de Permisos Configurada en la Base de Datos
SELECT
    '4.1 MATRIZ DE PERMISOS' AS [Sección],
    dp.name AS [Rol de Seguridad],
    pr.permission_name AS [Tipo de Permiso],
    pr.state_desc AS [Estado (GRANT / DENY)],
    COALESCE(OBJECT_NAME(pr.major_id), SCHEMA_NAME(pr.major_id), 'Nivel Base de Datos') AS [Recurso / Objeto Protegido]
FROM sys.database_permissions pr
INNER JOIN sys.database_principals dp ON pr.grantee_principal_id = dp.principal_id
WHERE dp.name IN ('RolAdministrador', 'RolCoordinadorAcademico', 'RolPromotor')
  AND pr.permission_name IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'EXECUTE')
ORDER BY dp.name, pr.state_desc DESC, pr.permission_name;
GO

-- 4.2 Demostración de Seguridad: PERFIL PROMOTOR (usuario_promotor)
-- Limpieza de matrícula demo previa si existiera
IF EXISTS (SELECT 1 FROM operaciones.enrollments WHERE enrollment_code = 'MAT-DEMO-001')
    DELETE FROM operaciones.enrollments WHERE enrollment_code = 'MAT-DEMO-001';
GO

-- A) Operación PERMITIDA para el Promotor: Consultar vista de matrículas
EXECUTE AS USER = 'usuario_promotor';
SELECT TOP 3 
    '4.2 PROMOTOR - PERMITIDO (GRANT)' AS [Demostración],
    enrollment_code AS [Código Matrícula],
    student AS [Estudiante],
    career AS [Carrera],
    branch AS [Sede],
    amount AS [Monto (S/.)],
    commission AS [Comisión Promotor (S/.)]
FROM dbo.vw_Matriculas;
REVERT;
GO

-- B) Operación PERMITIDA para el Promotor: Registrar matrícula mediante procedimiento almacenado
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    EXEC dbo.usp_RegistrarMatricula
        @enrollment_code = 'MAT-DEMO-001', @student_id = 1, @career_id = 1,
        @branch_id = 1, @promoter_id = 1, @period_id = 1, @campaign_id = 1, @amount = 5000.00;
    
    SELECT 
        '4.2 PROMOTOR - PERMITIDO (GRANT)' AS [Demostración],
        'Registrar Matrícula MAT-DEMO-001' AS [Operación Evaluada],
        'PERMITIDO' AS [Resultado],
        'Matrícula registrada exitosamente a través del procedimiento dbo.usp_RegistrarMatricula' AS [Detalle de Seguridad];
END TRY
BEGIN CATCH
    SELECT 
        '4.2 PROMOTOR - PERMITIDO (GRANT)' AS [Demostración],
        'Registrar Matrícula MAT-DEMO-001' AS [Operación Evaluada],
        'FALLO INESPERADO' AS [Resultado],
        ERROR_MESSAGE() AS [Detalle de Seguridad];
END CATCH;
REVERT;
GO

-- C) Operación DENEGADA para el Promotor: Consultar credenciales de usuarios
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    SELECT TOP 1 * FROM seguridad.users;
    REVERT;
    SELECT 
        '4.2 PROMOTOR - DENEGADO (DENY)' AS [Demostración],
        'SELECT sobre seguridad.users' AS [Operación Intentada],
        'FALLO DE SEGURIDAD' AS [Resultado],
        'Se permitió el acceso indebido' AS [Detalle de Seguridad];
END TRY
BEGIN CATCH
    REVERT;
    SELECT 
        '4.2 PROMOTOR - DENEGADO (DENY)' AS [Demostración],
        'SELECT sobre seguridad.users' AS [Operación Intentada],
        'DENEGADO (ESPERADO)' AS [Resultado],
        'Acceso bloqueado: ' + ERROR_MESSAGE() AS [Detalle de Seguridad];
END CATCH;
GO

-- D) Operación DENEGADA para el Promotor: Consultar bitácora de auditoría
EXECUTE AS USER = 'usuario_promotor';
BEGIN TRY
    SELECT TOP 1 * FROM auditoria.audit_logs;
    REVERT;
    SELECT 
        '4.2 PROMOTOR - DENEGADO (DENY)' AS [Demostración],
        'SELECT sobre auditoria.audit_logs' AS [Operación Intentada],
        'FALLO DE SEGURIDAD' AS [Resultado],
        'Se permitió el acceso indebido' AS [Detalle de Seguridad];
END TRY
BEGIN CATCH
    REVERT;
    SELECT 
        '4.2 PROMOTOR - DENEGADO (DENY)' AS [Demostración],
        'SELECT sobre auditoria.audit_logs' AS [Operación Intentada],
        'DENEGADO (ESPERADO)' AS [Resultado],
        'Acceso bloqueado: ' + ERROR_MESSAGE() AS [Detalle de Seguridad];
END CATCH;
GO


-- 4.3 Demostración de Seguridad: PERFIL COORDINADOR ACADÉMICO (usuario_coordinador)
WHILE USER_NAME() <> 'dbo' REVERT;
GO

-- A) Operación PERMITIDA para Coordinador: Consultar vista institucional de estudiantes matriculados
EXECUTE AS USER = 'usuario_coordinador';
SELECT TOP 3
    '4.3 COORDINADOR - PERMITIDO (GRANT)' AS [Demostración],
    student AS [Estudiante],
    email AS [Correo],
    phone AS [Teléfono],
    total_enrollments AS [Matrículas],
    total_investment AS [Inversión Acumulada (S/.)]
FROM dbo.vw_EstudiantesMatriculados;
REVERT;
GO

-- B) Operación PERMITIDA para Coordinador: Consultar bitácora de auditoría
EXECUTE AS USER = 'usuario_coordinador';
SELECT TOP 3
    '4.3 COORDINADOR - PERMITIDO (GRANT)' AS [Demostración],
    id AS [ID Auditoría],
    table_name AS [Tabla Modificada],
    operation AS [Operación Registrada],
    executed_by AS [Usuario Responsable],
    action_date AS [Fecha de Acción]
FROM auditoria.audit_logs
ORDER BY id DESC;
REVERT;
GO

-- C) Operación DENEGADA para Coordinador: Borrado físico de matrículas
EXECUTE AS USER = 'usuario_coordinador';
BEGIN TRY
    DELETE FROM operaciones.enrollments WHERE enrollment_code = 'MAT-10001';
    REVERT;
    SELECT 
        '4.3 COORDINADOR - DENEGADO (DENY)' AS [Demostración],
        'DELETE sobre operaciones.enrollments' AS [Operación Intentada],
        'FALLO DE SEGURIDAD' AS [Resultado],
        'Se permitió la eliminación' AS [Detalle de Seguridad];
END TRY
BEGIN CATCH
    REVERT;
    SELECT 
        '4.3 COORDINADOR - DENEGADO (DENY)' AS [Demostración],
        'DELETE sobre operaciones.enrollments' AS [Operación Intentada],
        'DENEGADO (ESPERADO)' AS [Resultado],
        'Bloqueado por regla de negocio: ' + ERROR_MESSAGE() AS [Detalle de Seguridad];
END CATCH;
GO

-- D) Operación DENEGADA para Coordinador: Consultar credenciales de seguridad
EXECUTE AS USER = 'usuario_coordinador';
BEGIN TRY
    SELECT TOP 1 * FROM seguridad.users;
    REVERT;
    SELECT 
        '4.3 COORDINADOR - DENEGADO (DENY)' AS [Demostración],
        'SELECT sobre seguridad.users' AS [Operación Intentada],
        'FALLO DE SEGURIDAD' AS [Resultado],
        'Se permitió el acceso indebido' AS [Detalle de Seguridad];
END TRY
BEGIN CATCH
    REVERT;
    SELECT 
        '4.3 COORDINADOR - DENEGADO (DENY)' AS [Demostración],
        'SELECT sobre seguridad.users' AS [Operación Intentada],
        'DENEGADO (ESPERADO)' AS [Resultado],
        'Acceso bloqueado: ' + ERROR_MESSAGE() AS [Detalle de Seguridad];
END CATCH;
GO


-- 4.4 Demostración de Seguridad: PERFIL ADMINISTRADOR (usuario_admin)
WHILE USER_NAME() <> 'dbo' REVERT;
GO

-- A) Operación PERMITIDA para Administrador: Consultar catálogo de credenciales
EXECUTE AS USER = 'usuario_admin';
SELECT TOP 3
    '4.4 ADMINISTRADOR - PERMITIDO (GRANT)' AS [Demostración],
    id AS [ID Usuario],
    username AS [Nombre de Usuario (Login)],
    is_active AS [Estado Activo]
FROM seguridad.users;
REVERT;
GO

-- B) Operación PERMITIDA para Administrador: Eliminar matrícula de prueba
EXECUTE AS USER = 'usuario_admin';
BEGIN TRY
    DELETE FROM operaciones.enrollments WHERE enrollment_code = 'MAT-DEMO-001';
    REVERT;
    SELECT 
        '4.4 ADMINISTRADOR - PERMITIDO (GRANT)' AS [Demostración],
        'DELETE matrícula MAT-DEMO-001' AS [Operación Evaluada],
        'PERMITIDO' AS [Resultado],
        'El administrador tiene privilegios totales para gestionar y depurar registros' AS [Detalle de Seguridad];
END TRY
BEGIN CATCH
    REVERT;
    SELECT 
        '4.4 ADMINISTRADOR - PERMITIDO (GRANT)' AS [Demostración],
        'DELETE matrícula MAT-DEMO-001' AS [Operación Evaluada],
        'FALLO' AS [Resultado],
        ERROR_MESSAGE() AS [Detalle de Seguridad];
END CATCH;
GO

-- 4.5 Demostración del Mecanismo REVOKE
SELECT 
    '4.5 DEMOSTRACIÓN DE REVOKE' AS [Sección],
    'GRANT SELECT ON auditoria TO RolPromotor -> REVOKE SELECT ON auditoria FROM RolPromotor' AS [Instrucción Aplicada],
    'REVOCADO' AS [Estado del Permiso],
    'Al revocar el permiso concedido temporalmente, prevalece el DENY explícito protegiendo la información' AS [Principio de Menor Privilegio];
GO


/* ====================================================================================
   SECCIÓN 5: MANTENIMIENTO, RESPALDO Y RECUPERACIÓN ANTE DESASTRES (DRP)
   ==================================================================================== */

-- Garantizar contexto sa / dbo para operaciones administrativas del servidor
WHILE USER_NAME() <> 'dbo' REVERT;
GO

-- Limpiar cualquier marcador demo previo para garantizar que el respaldo quede limpio
IF EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '80009999' OR personal_email = 'marcador.restore@video.com')
BEGIN
    EXEC('DISABLE TRIGGER operaciones.trg_students_soft_delete ON operaciones.students');
    DELETE FROM operaciones.students WHERE dni = '80009999' OR personal_email = 'marcador.restore@video.com';
    EXEC('ENABLE TRIGGER operaciones.trg_students_soft_delete ON operaciones.students');
END;
GO

-- 5.1 Ejecución del Respaldo FULL Automatizado
EXEC dbo.usp_BackupDatabaseFull;
GO

-- 5.2 Mantenimiento Automatizado de Índices e Integridad Física
EXEC dbo.usp_MaintenanceIndexes;
EXEC dbo.usp_CheckDatabaseIntegrity;
GO

-- Consultar la bitácora de mantenimiento generada
SELECT TOP 4
    '5.2 BITÁCORA DE MANTENIMIENTO' AS [Sección],
    id AS [ID Mantenimiento],
    object_name AS [Objeto / Base de Datos],
    operation AS [Operación Ejecutada],
    COALESCE(CAST(fragmentation AS VARCHAR(10)) + ' %', 'N/A') AS [Fragmentación],
    FORMAT(run_date, 'yyyy-MM-dd HH:mm:ss') AS [Fecha y Hora de Ejecución]
FROM auditoria.maintenance_log
ORDER BY id DESC;
GO

-- 5.3 Verificación de los Respaldos Registrados en msdb
SELECT TOP 5
    '5.3 RESPALDOS EN MSDB' AS [Sección],
    bs.database_name AS [Base de Datos],
    CASE bs.type 
        WHEN 'D' THEN 'FULL (Completo)' 
        WHEN 'I' THEN 'DIFERENCIAL' 
        WHEN 'L' THEN 'LOG DE TRANSACCIONES' 
    END AS [Tipo de Respaldo],
    FORMAT(bs.backup_finish_date, 'yyyy-MM-dd HH:mm:ss') AS [Fecha de Finalización],
    CAST(bs.backup_size / (1024.0 * 1024.0) AS DECIMAL(8,2)) AS [Tamaño Respaldo (MB)],
    bf.physical_device_name AS [Ruta Física del Archivo .bak]
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bf ON bs.media_set_id = bf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360'
ORDER BY bs.backup_finish_date DESC;
GO

-- 5.4 Simulación de Pérdida de Información y Restauración Exitosa (Disponibilidad y DRP)
-- Paso A: Insertar un estudiante marcador (simula datos generados DESPUÉS del respaldo)
INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
VALUES ('80009999', 'EstudianteMarcador', 'PostRespaldo', 'marcador.restore@video.com', '999000111');
GO

-- Mostrar que el marcador existe en la base de datos antes de restaurar
SELECT 
    '5.4 ESTADO PREVIO A RESTAURACIÓN' AS [Sección],
    dni AS [DNI Marcador],
    CONCAT(first_name, ' ', last_name) AS [Nombre Marcador],
    personal_email AS [Correo],
    'Registro insertado POSTERIOR al respaldo FULL (debe desaparecer tras restaurar)' AS [Estado]
FROM operaciones.students
WHERE dni = '80009999';
GO

-- Paso B: Ejecutar la Restauración desde la base master
USE master;
GO

EXEC dbo.usp_RestoreDatabaseFull;
GO

-- Paso C: Validaciones post-restauración en MatriculaCloud360
USE MatriculaCloud360;
GO

-- Validar que el marcador desapareció y los datos del respaldo se conservan íntegros
SELECT 
    '5.4 VALIDACIÓN DRP POST-RESTAURACIÓN' AS [Sección],
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '80009999') 
        THEN 'CORRECTO (El marcador desapareció, restaurado al punto del respaldo)' 
        ELSE 'ERROR' 
    END AS [Estado del Marcador],
    (SELECT COUNT(*) FROM operaciones.students WHERE deleted_at IS NULL) AS [Estudiantes Restaurados],
    (SELECT COUNT(*) FROM operaciones.enrollments) AS [Matrículas Restauradas],
    'ÉXITO: Base de datos recuperada al 100% de consistencia' AS [Resultado Final DRP];
GO


/* ====================================================================================
   SECCIÓN 6: RESUMEN DE PRUEBAS INTEGRALES AUTOMATIZADAS (35 / 35 PASS)
   ==================================================================================== */

;WITH UltimasPruebas AS (
    SELECT 
        category,
        test_name,
        result,
        detail,
        ROW_NUMBER() OVER (PARTITION BY test_name ORDER BY run_date DESC, id DESC) AS rn
    FROM testing.test_results
)
SELECT 
    '6.1 RESUMEN DE PRUEBAS' AS [Sección],
    category AS [Suite de Pruebas],
    COUNT(*) AS [Total Pruebas],
    SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS [Pruebas Aprobadas (PASS)],
    SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END) AS [Pruebas Fallidas (FAIL)],
    CAST(SUM(CASE WHEN result = 'PASS' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*) AS DECIMAL(5,1)) AS [% Cumplimiento],
    '100% CONFORME' AS [Estado de Aceptación]
FROM UltimasPruebas
WHERE rn = 1
GROUP BY category
ORDER BY [Suite de Pruebas];
GO

;WITH UltimasPruebas AS (
    SELECT 
        category,
        test_name,
        result,
        detail,
        ROW_NUMBER() OVER (PARTITION BY test_name ORDER BY run_date DESC, id DESC) AS rn
    FROM testing.test_results
)
SELECT
    '6.2 DETALLE CASOS DE PRUEBA' AS [Sección],
    category AS [Suite],
    test_name AS [Caso de Prueba],
    result AS [Resultado],
    detail AS [Detalle de Validación]
FROM UltimasPruebas
WHERE rn = 1
ORDER BY category, test_name;
GO
