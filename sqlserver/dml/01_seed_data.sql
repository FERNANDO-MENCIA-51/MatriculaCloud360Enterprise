/* Datos Semilla (Seed Data) Versión alineada con DDL actualizado */

USE MatriculaCloud360;
GO


-- ESQUEMA: seguridad


/* DATA: seguridad.roles */
IF NOT EXISTS (SELECT 1 FROM seguridad.roles WHERE name IN ('Administrador', 'Coordinador Academico', 'Promotor'))
BEGIN
    INSERT INTO seguridad.roles (name)
    VALUES ('Administrador'), ('Coordinador Academico'), ('Promotor');
END
GO

/* DATA: seguridad.users

   Se crean: 1 admin, 1 coordinador, 1 usuario por cada promotor */
IF NOT EXISTS (SELECT 1 FROM seguridad.users WHERE username = 'admin')
BEGIN
    INSERT INTO seguridad.users (role_id, username, password_hash, is_active)
    VALUES
        (1, 'admin',       'hash_admin_123',   1),   -- role_id 1 = Administrador
        (2, 'coord.acad',  'hash_coord_123',   1),   -- role_id 2 = Coordinador Academico
        (3, 'cmendoza',    'hash_cmendoza_123', 1),  -- role_id 3 = Promotor
        (3, 'lramirez',    'hash_lramirez_123', 1),  -- role_id 3 = Promotor
        (3, 'jvalladolid', 'hash_jvall_123',    1);  -- role_id 3 = Promotor
END
GO


-- ESQUEMA: academico - Catálogos


/* DATA: academico.branches (Sedes) */
IF NOT EXISTS (SELECT 1 FROM academico.branches WHERE code = 'SED-001')
BEGIN
    INSERT INTO academico.branches (code, name, city)
    VALUES
        ('SED-001', 'San Carlos',        'Chincha'),
        ('SED-002', 'Central',           'Cañete'),
        ('SED-003', 'Parque Empresarial', 'Ica'),
        ('SED-004', 'Miraflores',        'Lima');
END
GO

/* DATA: academico.careers (Carreras) */
IF NOT EXISTS (SELECT 1 FROM academico.careers WHERE code = 'CAR-101')
BEGIN
    INSERT INTO academico.careers (code, name, duration_cycles, total_investment)
    VALUES
        ('CAR-101', 'Desarrollo de Software',          6, 12000.00),
        ('CAR-102', 'Administracion de Empresas',       6, 15000.00),
        ('CAR-103', 'Marketing y Publicidad Digital',   4, 18000.00),
        ('CAR-104', 'Animacion Digital 3D',            6, 24000.00);
END
GO

/* DATA: academico.teachers (Docentes) */
IF NOT EXISTS (SELECT 1 FROM academico.teachers WHERE corporate_email = 'aturing@edufuturo.edu.pe')
BEGIN
    INSERT INTO academico.teachers (full_name, corporate_email, specialty)
    VALUES
        ('Alan Turing',     'aturing@edufuturo.edu.pe',   'Ingenieria de Software'),
        ('Philip Kotler',   'pkotler@edufuturo.edu.pe',   'Marketing y Ventas'),
        ('Peter Drucker',   'pdrucker@edufuturo.edu.pe',  'Gestion Empresarial'),
        ('Ed Catmull',      'ecatmull@edufuturo.edu.pe',  'Animacion y VFX');
END
GO

/* DATA: academico.academic_periods (Periodos Academicos) */
IF NOT EXISTS (SELECT 1 FROM academico.academic_periods WHERE name = '2025-I')
BEGIN
    INSERT INTO academico.academic_periods (name, start_date, end_date, is_active)
    VALUES ('2025-I', '2025-03-01', '2025-08-31', 1);
END
GO

/* DATA: academico.admission_campaigns (Campanas de Admision) */
IF NOT EXISTS (SELECT 1 FROM academico.admission_campaigns WHERE name = 'Admisión 2025-I')
BEGIN
    INSERT INTO academico.admission_campaigns (name, commission_percentage, is_active)
    VALUES ('Admision 2025-I', 5.00, 1);
END
GO

/* DATA: academico.courses (Cursos)
   Ahora cada curso se asigna a un teacher_id */
IF NOT EXISTS (SELECT 1 FROM academico.courses WHERE code = 'C-001')
BEGIN
    INSERT INTO academico.courses (code, name, credits, teacher_id)
    VALUES
        ('C-001', 'Logica de Programacion',   4, 1),   -- Alan Turing
        ('C-002', 'Diseno de Base de Datos',  3, 1),   -- Alan Turing
        ('C-003', 'Contabilidad General',      3, 3),   -- Peter Drucker
        ('C-004', 'Comportamiento del Consumidor', 3, 2), -- Philip Kotler
        ('C-005', 'Modelado 3D Basico',       4, 4),   -- Ed Catmull
        ('C-006', 'Etica Profesional',         2, 4);   -- Ed Catmull
END
GO

/* DATA: academico.career_courses (Asignacion de Cursos a Carreras) */
IF NOT EXISTS (SELECT 1 FROM academico.career_courses WHERE career_id = 1 AND course_id = 1)
BEGIN
    INSERT INTO academico.career_courses (career_id, course_id)
    VALUES
        -- Desarrollo de Software (CAR-101) -> Logica, BD, Etica
        (1, 1), (1, 2), (1, 6),
        -- Administracion (CAR-102) -> Contabilidad, Etica
        (2, 3), (2, 6),
        -- Marketing (CAR-103) -> Comportamiento Consumidor, Etica
        (3, 4), (3, 6),
        -- Animacion 3D (CAR-104) -> Modelado 3D, Etica
        (4, 5), (4, 6);
END
GO


-- ESQUEMA: operaciones


/* DATA: operaciones.students (Estudiantes) */
IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '75112233')
BEGIN
    INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
    VALUES
        ('75112233', 'Ana Maria',  'Perez Gomez',   'ana.perez@gmail.com',     '987654321'),
        ('48996655', 'Luis Felipe','Torres Rivas',   'luisf.torres@outlook.com','912345678'),
        ('70114477', 'Carmen',     'Rojas Silva',    'crojas_99@yahoo.com',     '945612378');
END
GO

/* DATA: operaciones.promoters (Promotores)
   Cada promoter se vincula a un user_id (seguridad.users) y base_branch_id (academico.branches)
   user_id: 3=cmendoza, 4=lramirez, 5=jvalladolid
   base_branch_id: 1=SED-001, 3=SED-003, 4=SED-004 */
IF NOT EXISTS (SELECT 1 FROM operaciones.promoters WHERE dni = '45889922')
BEGIN
    INSERT INTO operaciones.promoters (user_id, dni, full_name, base_branch_id, corporate_email)
    VALUES
        (3, '45889922', 'Carlos Mendoza',   1, 'cmendoza@edufuturo.edu.pe'),   -- SED-001
        (4, '71223344', 'Lucia Ramirez',     3, 'lramirez@edufuturo.edu.pe'),  -- SED-003
        (5, '42551188', 'Jorge Valladolid',  4, 'jvalladolid@edufuturo.edu.pe'); -- SED-004
END
GO


-- ESQUEMA: auditoria


/* DATA: auditoria.audit_logs */
IF NOT EXISTS (SELECT 1 FROM auditoria.audit_logs WHERE table_name = 'operaciones.enrollments' AND user_id = 1)
BEGIN
    INSERT INTO auditoria.audit_logs (user_id, table_name, operation)
    VALUES (1, 'operaciones.enrollments', 'INSERT');
END
GO


-- TRANSACCION: Matriculas (operaciones.enrollments)

-- Dependencias: students, careers, branches, promoters, periods, campaigns

IF NOT EXISTS (SELECT 1 FROM operaciones.enrollments WHERE enrollment_code = 'MAT-10001')
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO operaciones.enrollments (
            enrollment_code, student_id, career_id, branch_id,
            promoter_id, period_id, campaign_id, amount
        )
        VALUES
            -- Ana Maria -> Desarrollo Software, San Carlos, Carlos Mendoza
            ('MAT-10001', 1, 1, 1, 1, 1, 1, 4500.00),
            -- Luis Felipe -> Animacion 3D, Parque Empresarial, Lucia Ramirez
            ('MAT-10002', 2, 4, 3, 2, 1, 1, 4800.00),
            -- Carmen -> Marketing, Miraflores, Jorge Valladolid
            ('MAT-10003', 3, 3, 4, 3, 1, 1, 3200.00),
            -- Ana Maria -> Administracion, San Carlos, Carlos Mendoza (2da matricula)
            ('MAT-10004', 1, 2, 1, 1, 1, 1, 3800.00);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: La transaccion de matricula fallo y fue revertida.';
    END CATCH;
END
GO