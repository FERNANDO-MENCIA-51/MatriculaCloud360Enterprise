/* ============================================================
   SCRIPT DE SEGURIDAD - 01: LOGINS Y USUARIOS
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Perfiles definidos en el caso de negocio:
     - Administrador        (login_admin)        -> usuario_admin
     - Coordinador Academico (login_coordinador) -> usuario_coordinador
     - Promotor             (login_promotor)     -> usuario_promotor
   Nota: contrasenas de ejemplo para el entorno academico local.
   ============================================================ */

USE MatriculaCloud360;
GO

/* 1. LOGINS A NIVEL DE SERVIDOR */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_admin')
BEGIN
    CREATE LOGIN login_admin WITH PASSWORD = 'Admin2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = MatriculaCloud360;
    PRINT 'Login login_admin creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_coordinador')
BEGIN
    CREATE LOGIN login_coordinador WITH PASSWORD = 'Coord2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = MatriculaCloud360;
    PRINT 'Login login_coordinador creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_promotor')
BEGIN
    CREATE LOGIN login_promotor WITH PASSWORD = 'Promo2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = MatriculaCloud360;
    PRINT 'Login login_promotor creado.';
END
GO

/* 2. USUARIOS A NIVEL DE BASE DE DATOS */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_admin')
BEGIN
    CREATE USER usuario_admin FOR LOGIN login_admin;
    PRINT 'Usuario usuario_admin creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_coordinador')
BEGIN
    CREATE USER usuario_coordinador FOR LOGIN login_coordinador;
    PRINT 'Usuario usuario_coordinador creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_promotor')
BEGIN
    CREATE USER usuario_promotor FOR LOGIN login_promotor;
    PRINT 'Usuario usuario_promotor creado.';
END
GO

/* 3. SINCRONIZACION CON seguridad.users (para auditoria por triggers) */
IF NOT EXISTS (SELECT 1 FROM seguridad.users WHERE username = 'login_admin')
BEGIN
    INSERT INTO seguridad.users (role_id, username, password_hash, is_active)
    VALUES (1, 'login_admin', 'hash_admin_s3', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM seguridad.users WHERE username = 'login_coordinador')
BEGIN
    INSERT INTO seguridad.users (role_id, username, password_hash, is_active)
    VALUES (2, 'login_coordinador', 'hash_coord_s3', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM seguridad.users WHERE username = 'login_promotor')
BEGIN
    INSERT INTO seguridad.users (role_id, username, password_hash, is_active)
    VALUES (3, 'login_promotor', 'hash_promo_s3', 1);
END
GO

PRINT 'Logins y usuarios del Sprint 3 creados correctamente.';
GO