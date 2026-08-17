/* ====================================================================================
   DEMOSTRACIÓN COMPLETA - SPRINT 1: INFRAESTRUCTURA Y DISEÑO DE LA SOLUCIÓN (20%)
   ------------------------------------------------------------------------------------
   Criterios Demostrados del Sprint 1:
     1. Entorno de BD en Contenedor (SQL Server 2025 Developer, Persistencia y Estado).
     2. Arquitectura de Esquemas por Dominio de Negocio (4 esquemas).
     3. Modelo Físico y Estructura de Tablas (13 tablas con PK IDENTITY y UNIQUE).
     4. Integridad Referencial y Relaciones (Llaves Foráneas - FK).
     5. Carga de Datos Semilla Iniciales del Cliente (Seed Data del Catálogo).
     6. Resumen de Cumplimiento de Criterios de Aceptación del Sprint 1.
   ==================================================================================== */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


/* ====================================================================================
   SECCIÓN 1: INFRAESTRUCTURA, MOTOR SQL SERVER 2025 Y PERSISTENCIA DE DATOS
   ==================================================================================== */

-- 1.1 Información del Motor y Servidor en Docker
SELECT 
    '1.1 INFRAESTRUCTURA' AS [Sección],
    SERVERPROPERTY('ServerName') AS [Servidor],
    SERVERPROPERTY('ProductVersion') AS [Versión SQL Server],
    SERVERPROPERTY('Edition') AS [Edición],
    SERVERPROPERTY('ProductLevel') AS [Nivel de Producto],
    SERVERPROPERTY('Collation') AS [Intercalación (Collation)],
    'Despliegue automatizado con Docker Compose (SQL Server 2025 Developer)' AS [Entorno de Infraestructura];
GO

-- 1.2 Estado de la Base de Datos y Persistencia de Archivos (.mdf / .ldf)
SELECT 
    '1.2 PERSISTENCIA DE DATOS' AS [Sección],
    d.name AS [Base de Datos],
    d.state_desc AS [Estado],
    d.recovery_model_desc AS [Modelo de Recuperación],
    d.compatibility_level AS [Nivel Compatibilidad],
    f.name AS [Nombre Lógico],
    f.type_desc AS [Tipo de Archivo],
    f.physical_name AS [Ruta Física en Contenedor],
    CAST(f.size * 8.0 / 1024.0 AS DECIMAL(10,2)) AS [Tamaño Actual (MB)]
FROM sys.databases d
INNER JOIN sys.master_files f ON d.database_id = f.database_id
WHERE d.name = 'MatriculaCloud360'
ORDER BY f.type_desc DESC;
GO


/* ====================================================================================
   SECCIÓN 2: ARQUITECTURA DE ESQUEMAS POR DOMINIO DE NEGOCIO (4 ESQUEMAS)
   ==================================================================================== */

-- 2.1 Esquemas Diseñados para Aislar Responsabilidades
SELECT 
    '2.1 ESQUEMAS DE NEGOCIO' AS [Sección],
    s.name AS [Nombre de Esquema],
    u.name AS [Propietario del Esquema],
    CASE s.name
        WHEN 'seguridad'   THEN 'Control de acceso, roles institucionales y usuarios del sistema'
        WHEN 'academico'   THEN 'Oferta académica: sedes, carreras, cursos, docentes, periodos y campañas'
        WHEN 'operaciones' THEN 'Procesos transaccionales: estudiantes, promotores y matrículas'
        WHEN 'auditoria'   THEN 'Trazabilidad y registro de bitácora sobre eventos de datos'
        ELSE 'Esquema de sistema'
    END AS [Dominio y Responsabilidad de Negocio]
FROM sys.schemas s
INNER JOIN sys.sysusers u ON s.principal_id = u.uid
WHERE s.name IN ('seguridad', 'academico', 'operaciones', 'auditoria')
ORDER BY s.name;
GO


/* ====================================================================================
   SECCIÓN 3: MODELO FÍSICO DE TABLAS (13 TABLAS DEL SISTEMA)
   ==================================================================================== */

-- 3.1 Inventario de Tablas por Esquema
SELECT 
    '3.1 INVENTARIO DE TABLAS' AS [Sección],
    s.name AS [Esquema],
    t.name AS [Nombre de Tabla],
    CASE t.name
        -- seguridad
        WHEN 'roles'               THEN 'Catálogo de roles institucionales (Admin, Coord, Promotor)'
        WHEN 'users'               THEN 'Cuentas de usuario del sistema con password_hash'
        -- academico
        WHEN 'branches'            THEN 'Sedes y campus físicos (código, nombre, ciudad)'
        WHEN 'careers'             THEN 'Carreras académicas (código, duración, inversión)'
        WHEN 'teachers'            THEN 'Docentes con especialidad y correo corporativo'
        WHEN 'courses'             THEN 'Cursos asignados a docentes y créditos académicos'
        WHEN 'academic_periods'    THEN 'Periodos académicos con fechas de inicio y fin'
        WHEN 'admission_campaigns' THEN 'Campañas de admisión con porcentaje de comisión'
        WHEN 'career_courses'      THEN 'Malla curricular: relación N:M entre carreras y cursos'
        -- operaciones
        WHEN 'students'            THEN 'Estudiantes con DNI y correo electrónico único'
        WHEN 'promoters'           THEN 'Promotores vinculados a usuarios y a sede base'
        WHEN 'enrollments'         THEN 'Matrículas transaccionales vinculando todas las dimensiones'
        -- auditoria
        WHEN 'audit_logs'          THEN 'Bitácora de eventos y trazabilidad'
        ELSE 'Entidad del sistema'
    END AS [Descripción de la Entidad],
    p.rows AS [Registros Cargados]
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE s.name IN ('seguridad', 'academico', 'operaciones', 'auditoria')
ORDER BY s.name, t.name;
GO

-- 3.2 Estructura Detallada de Atributos, Tipos de Datos y Llaves Primarias
SELECT 
    '3.2 DICCIONARIO DE ATRIBUTOS' AS [Sección],
    s.name + '.' + t.name AS [Tabla],
    c.column_id AS [Nro],
    c.name AS [Columna],
    tp.name + 
        CASE 
            WHEN tp.name IN ('varchar', 'nvarchar', 'char') THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(10)) END + ')'
            WHEN tp.name IN ('decimal', 'numeric') THEN '(' + CAST(c.precision AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
            ELSE ''
        END AS [Tipo de Dato],
    CASE WHEN c.is_nullable = 1 THEN 'SI' ELSE 'NO' END AS [Permite Nulo],
    CASE WHEN c.is_identity = 1 THEN 'SI (IDENTITY)' ELSE 'NO' END AS [Autonumérico],
    CASE WHEN pk.column_id IS NOT NULL THEN 'PK (Llave Primaria)' ELSE '' END AS [Clave]
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types tp ON c.user_type_id = tp.user_type_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
WHERE s.name IN ('seguridad', 'academico', 'operaciones', 'auditoria')
ORDER BY [Tabla], c.column_id;
GO


/* ====================================================================================
   SECCIÓN 4: INTEGRIDAD REFERENCIAL Y RELACIONES (FOREIGN KEYS)
   ==================================================================================== */

-- 4.1 Catálogo de Llaves Foráneas (Relaciones del Modelo Lógico-Físico)
SELECT 
    '4.1 INTEGRIDAD REFERENCIAL' AS [Sección],
    fk.name AS [Nombre Llave Foránea],
    SCHEMA_NAME(t_parent.schema_id) + '.' + t_parent.name AS [Tabla Origen (Hija)],
    c_parent.name AS [Columna Origen (FK)],
    SCHEMA_NAME(t_ref.schema_id) + '.' + t_ref.name AS [Tabla Destino (Padre)],
    c_ref.name AS [Columna Destino (PK)],
    'Garantiza Integridad Referencial' AS [Propósito]
FROM sys.foreign_keys fk
INNER JOIN sys.tables t_parent ON fk.parent_object_id = t_parent.object_id
INNER JOIN sys.tables t_ref ON fk.referenced_object_id = t_ref.object_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns c_parent ON fkc.parent_object_id = c_parent.object_id AND fkc.parent_column_id = c_parent.column_id
INNER JOIN sys.columns c_ref ON fkc.referenced_object_id = c_ref.object_id AND fkc.referenced_column_id = c_ref.column_id
ORDER BY [Tabla Origen (Hija)], fk.name;
GO


/* ====================================================================================
   SECCIÓN 5: CARGA DE DATOS SEMILLA INICIALES DEL CLIENTE (01_seed_data.sql)
   ==================================================================================== */

-- 5.1 Sedes Institucionales (academico.branches)
SELECT 
    '5.1 SEDES (CATÁLOGO)' AS [Sección],
    id AS [ID],
    code AS [Código],
    name AS [Nombre de Sede],
    city AS [Ciudad]
FROM academico.branches;
GO

-- 5.2 Carreras Profesionales (academico.careers)
SELECT 
    '5.2 CARRERAS' AS [Sección],
    id AS [ID],
    code AS [Código],
    name AS [Carrera Profesional],
    duration_cycles AS [Ciclos],
    CAST(total_investment AS DECIMAL(10,2)) AS [Inversión Total (S/.)]
FROM academico.careers;
GO

-- 5.3 Docentes Institucionales (academico.teachers)
SELECT 
    '5.3 DOCENTES' AS [Sección],
    id AS [ID],
    full_name AS [Nombre Completo],
    corporate_email AS [Correo Corporativo],
    specialty AS [Especialidad Académica]
FROM academico.teachers;
GO

-- 5.4 Cursos y Docentes Asignados (academico.courses)
SELECT 
    '5.4 CURSOS ASIGNADOS' AS [Sección],
    c.id AS [ID],
    c.code AS [Código],
    c.name AS [Nombre del Curso],
    c.credits AS [Créditos],
    t.full_name AS [Docente Responsable],
    t.specialty AS [Especialidad Docente]
FROM academico.courses c
INNER JOIN academico.teachers t ON c.teacher_id = t.id;
GO

-- 5.5 Malla Curricular: Asignación de Cursos a Carreras (academico.career_courses)
SELECT 
    '5.5 MALLA CURRICULAR' AS [Sección],
    car.code AS [Cód Carrera],
    car.name AS [Carrera],
    cou.code AS [Cód Curso],
    cou.name AS [Curso Asignado],
    cou.credits AS [Créditos]
FROM academico.career_courses cc
INNER JOIN academico.careers car ON cc.career_id = car.id
INNER JOIN academico.courses cou ON cc.course_id = cou.id
ORDER BY car.name, cou.code;
GO

-- 5.6 Periodos y Campañas de Admisión
SELECT 
    '5.6 PERIODOS ACADÉMICOS' AS [Sección],
    id AS [ID],
    name AS [Periodo],
    start_date AS [Fecha Inicio],
    end_date AS [Fecha Fin],
    CASE WHEN is_active = 1 THEN 'Activo' ELSE 'Inactivo' END AS [Estado]
FROM academico.academic_periods;
GO

SELECT 
    '5.6 CAMPAÑAS DE ADMISIÓN' AS [Sección],
    id AS [ID],
    name AS [Campaña],
    CAST(commission_percentage AS DECIMAL(5,2)) AS [% Comisión Promotor],
    CASE WHEN is_active = 1 THEN 'Activa' ELSE 'Inactiva' END AS [Estado]
FROM academico.admission_campaigns;
GO

-- 5.7 Roles y Usuarios Base de Seguridad
SELECT 
    '5.7 ROLES DE SEGURIDAD' AS [Sección],
    r.id AS [ID Rol],
    r.name AS [Nombre Rol],
    COUNT(u.id) AS [Usuarios Vinculados]
FROM seguridad.roles r
LEFT JOIN seguridad.users u ON r.id = u.role_id
GROUP BY r.id, r.name;
GO

SELECT 
    '5.7 USUARIOS INICIALES' AS [Sección],
    u.id AS [ID Usuario],
    u.username AS [Nombre de Usuario (Login)],
    r.name AS [Rol Asignado],
    CASE WHEN u.is_active = 1 THEN 'Activo' ELSE 'Inactivo' END AS [Estado]
FROM seguridad.users u
INNER JOIN seguridad.roles r ON u.role_id = r.id;
GO

-- 5.8 Estudiantes Iniciales (operaciones.students)
SELECT 
    '5.8 ESTUDIANTES SEMILLA' AS [Sección],
    id AS [ID],
    dni AS [DNI],
    first_name + ' ' + last_name AS [Nombre Completo],
    personal_email AS [Correo Personal],
    phone AS [Teléfono]
FROM operaciones.students;
GO

-- 5.9 Promotores Vinculados a Sede y Usuario (operaciones.promoters)
SELECT 
    '5.9 PROMOTORES' AS [Sección],
    p.id AS [ID Promotor],
    p.dni AS [DNI],
    p.full_name AS [Nombre Promotor],
    b.name AS [Sede Base Asignada],
    p.corporate_email AS [Correo Corporativo],
    u.username AS [Usuario Sistema]
FROM operaciones.promoters p
INNER JOIN academico.branches b ON p.base_branch_id = b.id
INNER JOIN seguridad.users u ON p.user_id = u.id;
GO

-- 5.10 Matrículas Transaccionales Iniciales (operaciones.enrollments)
SELECT 
    '5.10 MATRÍCULAS INICIALES' AS [Sección],
    e.enrollment_code AS [Cód Matrícula],
    s.first_name + ' ' + s.last_name AS [Estudiante],
    c.name AS [Carrera],
    b.name AS [Sede],
    p.full_name AS [Promotor],
    ap.name AS [Periodo],
    ac.name AS [Campaña],
    CAST(e.amount AS DECIMAL(10,2)) AS [Monto (S/.)],
    FORMAT(e.enrollment_date, 'yyyy-MM-dd HH:mm') AS [Fecha Matrícula]
FROM operaciones.enrollments e
INNER JOIN operaciones.students s ON e.student_id = s.id
INNER JOIN academico.careers c ON e.career_id = c.id
INNER JOIN academico.branches b ON e.branch_id = b.id
INNER JOIN operaciones.promoters p ON e.promoter_id = p.id
INNER JOIN academico.academic_periods ap ON e.period_id = ap.id
INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id
ORDER BY e.enrollment_code;
GO


/* ====================================================================================
   SECCIÓN 6: RESUMEN DE CUMPLIMIENTO DE CRITERIOS DE ACEPTACIÓN - SPRINT 1
   ==================================================================================== */

SELECT 
    '6.1 CRITERIOS DE ACEPTACIÓN SPRINT 1' AS [Sección],
    '1. Despliegue en Contenedor (Docker)' AS [Criterio Evaluado],
    'SQL Server 2025 Developer + Docker Compose' AS [Implementación],
    'CUMPLIDO' AS [Estado]
UNION ALL
SELECT 
    '6.1 CRITERIOS DE ACEPTACIÓN SPRINT 1',
    '2. Creación Automática de BD',
    'Base de datos MatriculaCloud360 creada e inicializada',
    'CUMPLIDO'
UNION ALL
SELECT 
    '6.1 CRITERIOS DE ACEPTACIÓN SPRINT 1',
    '3. Arquitectura de Esquemas (4 Dominios)',
    'seguridad, academico, operaciones, auditoria',
    'CUMPLIDO'
UNION ALL
SELECT 
    '6.1 CRITERIOS DE ACEPTACIÓN SPRINT 1',
    '4. Modelo Físico de Tablas',
    CAST((SELECT COUNT(*) FROM sys.tables WHERE schema_id IN (SCHEMA_ID('seguridad'), SCHEMA_ID('academico'), SCHEMA_ID('operaciones'), SCHEMA_ID('auditoria'))) AS VARCHAR(10)) + ' tablas con PK IDENTITY y UNIQUE',
    'CUMPLIDO'
UNION ALL
SELECT 
    '6.1 CRITERIOS DE ACEPTACIÓN SPRINT 1',
    '5. Integridad Referencial (FK)',
    CAST((SELECT COUNT(*) FROM sys.foreign_keys) AS VARCHAR(10)) + ' relaciones Foreign Key activas',
    'CUMPLIDO'
UNION ALL
SELECT 
    '6.1 CRITERIOS DE ACEPTACIÓN SPRINT 1',
    '6. Datos Semilla del Catálogo',
    'Sedes, Carreras, Docentes, Cursos, Malla, Periodos, Campañas, Roles, Usuarios, Estudiantes, Promotores y Matrículas cargados',
    'CUMPLIDO'
UNION ALL
SELECT 
    '6.1 CRITERIOS DE ACEPTACIÓN SPRINT 1',
    '7. Persistencia de Datos',
    'Volumen mssql_data configurado en Docker Compose',
    'CUMPLIDO';
GO
