/* ============================================================
   SCRIPT DE SEGURIDAD - 02: ROLES DE BASE DE DATOS
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Se crean 3 roles de base de datos alineados con los perfiles
   del caso de negocio y se asignan los usuarios correspondientes.
   ============================================================ */

USE MatriculaCloud360;
GO

/* 1. CREACION DE ROLES */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'RolAdministrador')
BEGIN
    CREATE ROLE RolAdministrador;
    PRINT 'Rol RolAdministrador creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'RolCoordinadorAcademico')
BEGIN
    CREATE ROLE RolCoordinadorAcademico;
    PRINT 'Rol RolCoordinadorAcademico creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'RolPromotor')
BEGIN
    CREATE ROLE RolPromotor;
    PRINT 'Rol RolPromotor creado.';
END
GO

/* 2. ASIGNACION DE USUARIOS A ROLES */
IF IS_ROLEMEMBER('RolAdministrador', 'usuario_admin') = 0
BEGIN
    ALTER ROLE RolAdministrador ADD MEMBER usuario_admin;
    PRINT 'usuario_admin asignado a RolAdministrador.';
END
GO

IF IS_ROLEMEMBER('RolCoordinadorAcademico', 'usuario_coordinador') = 0
BEGIN
    ALTER ROLE RolCoordinadorAcademico ADD MEMBER usuario_coordinador;
    PRINT 'usuario_coordinador asignado a RolCoordinadorAcademico.';
END
GO

IF IS_ROLEMEMBER('RolPromotor', 'usuario_promotor') = 0
BEGIN
    ALTER ROLE RolPromotor ADD MEMBER usuario_promotor;
    PRINT 'usuario_promotor asignado a RolPromotor.';
END
GO

/* 3. VERIFICACION */
SELECT
    dp.name AS usuario,
    r.name AS rol
FROM sys.database_principals dp
INNER JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name IN ('usuario_admin', 'usuario_coordinador', 'usuario_promotor')
ORDER BY dp.name;
GO

PRINT 'Roles de base de datos del Sprint 3 configurados correctamente.';
GO