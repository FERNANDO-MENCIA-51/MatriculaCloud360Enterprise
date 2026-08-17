/* ============================================================
   SCRIPT DE SEGURIDAD - 03: PERMISOS POR ROL
   Sprint 3 - MatriculaCloud360Enterprise
   ------------------------------------------------------------
   Matriz de permisos (GRANT / DENY / REVOKE):

   | Recurso                    | Administrador | Coordinador | Promotor |
   |----------------------------|---------------|-------------|----------|
   | SELECT academico/operaciones| GRANT        | GRANT       | parcial  |
   | INSERT/UPDATE/DELETE tablas | GRANT        | DENY        | DENY     |
   | DELETE enrollments          | GRANT        | DENY        | DENY     |
   | SELECT seguridad            | GRANT        | DENY        | DENY     |
   | SELECT auditoria            | GRANT        | GRANT       | DENY     |
   | EXECUTE procedures          | GRANT        | GRANT       | solo 2   |
   | vw_EstudiantesMatriculados  | GRANT        | GRANT       | DENY     |
   | vw_Matriculas               | GRANT        | GRANT       | GRANT    |
   ============================================================ */

USE MatriculaCloud360;
GO

/* ============================================================
   1. ROL ADMINISTRADOR: control total sobre los esquemas
   ============================================================ */
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::academico   TO RolAdministrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::operaciones TO RolAdministrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::seguridad   TO RolAdministrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::auditoria   TO RolAdministrador;
GRANT SELECT ON dbo.vw_Matriculas TO RolAdministrador;
GRANT SELECT ON dbo.vw_EstudiantesMatriculados TO RolAdministrador;
GRANT EXECUTE ON SCHEMA::dbo TO RolAdministrador;
PRINT 'Permisos del RolAdministrador otorgados.';
GO

/* ============================================================
   2. ROL COORDINADOR ACADEMICO: lectura de datos, ejecucion de
   procedimientos; sin borrado fisico de matriculas ni acceso
   a la informacion de seguridad.
   ============================================================ */
GRANT SELECT ON SCHEMA::academico   TO RolCoordinadorAcademico;
GRANT SELECT ON SCHEMA::operaciones TO RolCoordinadorAcademico;
GRANT SELECT ON SCHEMA::auditoria   TO RolCoordinadorAcademico;
GRANT SELECT ON dbo.vw_Matriculas TO RolCoordinadorAcademico;
GRANT SELECT ON dbo.vw_EstudiantesMatriculados TO RolCoordinadorAcademico;
GRANT EXECUTE ON SCHEMA::dbo TO RolCoordinadorAcademico;

-- DENY: no puede eliminar matriculas (registro transaccional)
DENY DELETE ON operaciones.enrollments TO RolCoordinadorAcademico;
-- DENY: no puede eliminar estudiantes fisicamente (soft-delete via procedimiento)
DENY DELETE ON operaciones.students TO RolCoordinadorAcademico;
-- DENY: no puede consultar credenciales de seguridad
DENY SELECT ON SCHEMA::seguridad TO RolCoordinadorAcademico;
PRINT 'Permisos del RolCoordinadorAcademico otorgados.';
GO

/* ============================================================
   3. ROL PROMOTOR: operaciones de matricula y consulta limitada
   ============================================================ */
-- Operaciones autorizadas para su perfil
GRANT SELECT ON operaciones.students TO RolPromotor;
GRANT SELECT ON operaciones.enrollments TO RolPromotor;
GRANT SELECT ON dbo.vw_Matriculas TO RolPromotor;
GRANT EXECUTE ON dbo.usp_RegistrarMatricula TO RolPromotor;
GRANT EXECUTE ON dbo.usp_ObtenerMatricula TO RolPromotor;
GRANT EXECUTE ON dbo.fn_CalcularComision TO RolPromotor;

-- DENY: no puede modificar datos directamente
DENY INSERT, UPDATE, DELETE ON SCHEMA::operaciones TO RolPromotor;
DENY INSERT, UPDATE, DELETE ON SCHEMA::academico TO RolPromotor;
-- DENY: no puede consultar informacion sensible
DENY SELECT ON SCHEMA::seguridad TO RolPromotor;
DENY SELECT ON SCHEMA::auditoria TO RolPromotor;
-- DENY: la vista institucional es exclusiva de coordinador/administrador
DENY SELECT ON dbo.vw_EstudiantesMatriculados TO RolPromotor;
PRINT 'Permisos del RolPromotor otorgados.';
GO

/* ============================================================
   4. EJEMPLO DE REVOKE: se otorga y luego se revoca el acceso
   del promotor a la auditoria, dejando el permiso inexistente
   (y el DENY anterior como regla efectiva).
   ============================================================ */
GRANT SELECT ON SCHEMA::auditoria TO RolPromotor;
REVOKE SELECT ON SCHEMA::auditoria FROM RolPromotor;
PRINT 'Ejemplo de REVOKE aplicado sobre RolPromotor/auditoria.';
GO

/* 5. VERIFICACION DE PERMISOS */
SELECT
    dp.name AS usuario,
    pr.permission_name,
    pr.state_desc,
    OBJECT_NAME(pr.major_id) AS recurso
FROM sys.database_permissions pr
INNER JOIN sys.database_principals dp ON pr.grantee_principal_id = dp.principal_id
WHERE dp.name IN ('RolAdministrador', 'RolCoordinadorAcademico', 'RolPromotor')
  AND pr.permission_name IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'EXECUTE')
ORDER BY dp.name, pr.permission_name;
GO

PRINT 'Matriz de permisos del Sprint 3 aplicada correctamente.';
GO