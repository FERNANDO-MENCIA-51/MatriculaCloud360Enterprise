
/* Creación de Tablas por Esquema */


USE MatriculaCloud360;
GO


-- ESQUEMA: seguridad


/* TABLA: seguridad.roles */
IF OBJECT_ID(N'seguridad.roles', N'U') IS NULL
BEGIN
    CREATE TABLE seguridad.roles (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name VARCHAR(50) NOT NULL
    );
END
GO

/* TABLA: seguridad.users */
IF OBJECT_ID(N'seguridad.users', N'U') IS NULL
BEGIN
    CREATE TABLE seguridad.users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        role_id INT NOT NULL,
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        is_active BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_users_roles FOREIGN KEY (role_id) REFERENCES seguridad.roles(id)
    );
END
GO


-- ESQUEMA: auditoria


/* TABLA: auditoria.audit_logs */
IF OBJECT_ID(N'auditoria.audit_logs', N'U') IS NULL
BEGIN
    CREATE TABLE auditoria.audit_logs (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        table_name VARCHAR(50) NOT NULL,
        operation VARCHAR(10) NOT NULL,
        action_date DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_audit_logs_users FOREIGN KEY (user_id) REFERENCES seguridad.users(id)
    );
END
GO


-- ESQUEMA: academico (Catálogos y Estructura Educativa)


/* TABLA: academico.branches (Sedes) */
IF OBJECT_ID(N'academico.branches', N'U') IS NULL
BEGIN
    CREATE TABLE academico.branches (
        id INT IDENTITY(1,1) PRIMARY KEY,
        code VARCHAR(10) NOT NULL UNIQUE,
        name VARCHAR(100) NOT NULL,
        city VARCHAR(50) NOT NULL,
        deleted_at DATETIME NULL
    );
END
GO

/* TABLA: academico.careers (Carreras) */
IF OBJECT_ID(N'academico.careers', N'U') IS NULL
BEGIN
    CREATE TABLE academico.careers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        code VARCHAR(10) NOT NULL UNIQUE,
        name VARCHAR(100) NOT NULL,
        duration_cycles INT NOT NULL,
        total_investment DECIMAL(10,2) NOT NULL,
        deleted_at DATETIME NULL
    );
END
GO

/* TABLA: academico.teachers (Docentes) */
IF OBJECT_ID(N'academico.teachers', N'U') IS NULL
BEGIN
    CREATE TABLE academico.teachers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        full_name VARCHAR(150) NOT NULL,
        specialty VARCHAR(100) NOT NULL,
        corporate_email VARCHAR(100) NOT NULL UNIQUE,
        deleted_at DATETIME NULL
    );
END
GO

/* TABLA: academico.academic_periods (Periodos Académicos) */
IF OBJECT_ID(N'academico.academic_periods', N'U') IS NULL
BEGIN
    CREATE TABLE academico.academic_periods (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name VARCHAR(20) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        is_active BIT NOT NULL DEFAULT 1,
        deleted_at DATETIME NULL
    );
END
GO

/* TABLA: academico.admission_campaigns (Campañas de Admisión) */
IF OBJECT_ID(N'academico.admission_campaigns', N'U') IS NULL
BEGIN
    CREATE TABLE academico.admission_campaigns (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        commission_percentage DECIMAL(5,2) NOT NULL,
        is_active BIT NOT NULL DEFAULT 1,
        deleted_at DATETIME NULL
    );
END
GO

/* TABLA: academico.courses (Cursos) */
IF OBJECT_ID(N'academico.courses', N'U') IS NULL
BEGIN
    CREATE TABLE academico.courses (
        id INT IDENTITY(1,1) PRIMARY KEY,
        code VARCHAR(10) NOT NULL UNIQUE,
        name VARCHAR(100) NOT NULL,
        credits INT NOT NULL,
        teacher_id INT NOT NULL,
        deleted_at DATETIME NULL,
        CONSTRAINT FK_courses_teachers FOREIGN KEY (teacher_id) REFERENCES academico.teachers(id)
    );
END
GO

/* TABLA: academico.career_courses (Relación Carrera - Curso) */
IF OBJECT_ID(N'academico.career_courses', N'U') IS NULL
BEGIN
    CREATE TABLE academico.career_courses (
        career_id INT NOT NULL,
        course_id INT NOT NULL,
        PRIMARY KEY (career_id, course_id),
        CONSTRAINT FK_career_courses_careers FOREIGN KEY (career_id) REFERENCES academico.careers(id),
        CONSTRAINT FK_career_courses_courses FOREIGN KEY (course_id) REFERENCES academico.courses(id)
    );
END
GO


-- ESQUEMA: operaciones (Estudiantes, Promotores y Matrículas)


/* TABLA: operaciones.students (Estudiantes) */
IF OBJECT_ID(N'operaciones.students', N'U') IS NULL
BEGIN
    CREATE TABLE operaciones.students (
        id INT IDENTITY(1,1) PRIMARY KEY,
        dni VARCHAR(15) NOT NULL UNIQUE,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        personal_email VARCHAR(100) NOT NULL UNIQUE,
        phone VARCHAR(20) NULL,
        deleted_at DATETIME NULL
    );
END
GO

/* TABLA: operaciones.promoters (Promotores) */
IF OBJECT_ID(N'operaciones.promoters', N'U') IS NULL
BEGIN
    CREATE TABLE operaciones.promoters (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL UNIQUE,
        dni VARCHAR(15) NOT NULL UNIQUE,
        full_name VARCHAR(150) NOT NULL,
        base_branch_id INT NOT NULL,
        corporate_email VARCHAR(100) NOT NULL UNIQUE,
        deleted_at DATETIME NULL,
        CONSTRAINT FK_promoters_users FOREIGN KEY (user_id) REFERENCES seguridad.users(id),
        CONSTRAINT FK_promoters_branches FOREIGN KEY (base_branch_id) REFERENCES academico.branches(id)
    );
END
GO

/* TABLA: operaciones.enrollments (Matrículas) */
IF OBJECT_ID(N'operaciones.enrollments', N'U') IS NULL
BEGIN
    CREATE TABLE operaciones.enrollments (
        id INT IDENTITY(1,1) PRIMARY KEY,
        enrollment_code VARCHAR(20) NOT NULL UNIQUE,
        student_id INT NOT NULL,
        career_id INT NOT NULL,
        branch_id INT NOT NULL,
        promoter_id INT NOT NULL,
        period_id INT NOT NULL,
        campaign_id INT NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        enrollment_date DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_enrollments_students FOREIGN KEY (student_id) REFERENCES operaciones.students(id),
        CONSTRAINT FK_enrollments_careers FOREIGN KEY (career_id) REFERENCES academico.careers(id),
        CONSTRAINT FK_enrollments_branches FOREIGN KEY (branch_id) REFERENCES academico.branches(id),
        CONSTRAINT FK_enrollments_promoters FOREIGN KEY (promoter_id) REFERENCES operaciones.promoters(id),
        CONSTRAINT FK_enrollments_periods FOREIGN KEY (period_id) REFERENCES academico.academic_periods(id),
        CONSTRAINT FK_enrollments_campaigns FOREIGN KEY (campaign_id) REFERENCES academico.admission_campaigns(id)
    );
END
GO
