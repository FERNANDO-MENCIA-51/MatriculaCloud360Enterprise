# Usuarios y permisos

Matriz de credenciales y permisos de los tres perfiles del sistema: Administrador, Coordinador Académico y Promotor.

---

## 1. Credenciales de acceso

| Login | Usuario DB | Rol | Contraseña |
|---|---|---|---|
| `login_admin` | `usuario_admin` | `RolAdministrador` | `Admin2026` |
| `login_coordinador` | `usuario_coordinador` | `RolCoordinadorAcademico` | `Coord2026` |
| `login_promotor` | `usuario_promotor` | `RolPromotor` | `Promo2026` |

---

## 2. Matriz de permisos por operación

| Operación | Promotor | Coordinador | Administrador |
|---|---|---|---|
| Ver `vw_Matriculas` | SI | SI | SI |
| Ver `vw_EstudiantesMatriculados` | NO | SI | SI |
| Ver `seguridad.users` | NO | NO | SI |
| Ver `auditoria.audit_logs` | NO | SI | SI |
| Registrar matrícula (vía procedimiento) | SI | SI | SI |
| Registrar/actualizar estudiantes (vía procedimiento) | NO | SI | SI |
| Borrar datos directamente | NO | NO | SI |

---

## 3. Alcance por rol

### RolAdministrador (`login_admin`)

- Acceso total a todos los esquemas: `academico`, `operaciones`, `seguridad`, `auditoria`.
- Puede ejecutar cualquier operación SQL: SELECT, INSERT, UPDATE, DELETE.
- Ve las credenciales de `seguridad.users`.
- Puede eliminar matrículas y cualquier otro registro directamente.
- Tiene acceso a las vistas `vw_Matriculas` y `vw_EstudiantesMatriculados`.
- Tiene acceso a la bitácora de auditoría y mantenimiento.

### RolCoordinadorAcademico (`login_coordinador`)

- Lectura sobre `academico` y `operaciones`.
- Lectura sobre `auditoria.audit_logs`.
- Acceso a las vistas `vw_Matriculas` y `vw_EstudiantesMatriculados`.
- Ejecución de procedimientos almacenados autorizados.
- **NO** puede eliminar matrículas directamente (`DENY DELETE ON operaciones.enrollments`).
- **NO** puede eliminar estudiantes físicamente (`DENY DELETE ON operaciones.students`).
- **NO** puede consultar `seguridad.users` (`DENY SELECT ON SCHEMA::seguridad`).

### RolPromotor (`login_promotor`)

- SELECT sobre `operaciones.students` y `operaciones.enrollments`.
- Acceso a la vista `vw_Matriculas`.
- Ejecución de `usp_RegistrarMatricula`, `usp_ObtenerMatricula` y `fn_CalcularComision`.
- **NO** puede modificar datos directamente (`DENY INSERT, UPDATE, DELETE` en `operaciones` y `academico`).
- **NO** puede consultar `seguridad.users` ni `auditoria.audit_logs`.
- **NO** puede ver `vw_EstudiantesMatriculados`.

---

## 4. Mecanismo de seguridad

Los procedimientos de escritura (`usp_RegistrarEstudiante`, `usp_ActualizarEstudiante`, `usp_EliminarEstudiante`, `usp_RegistrarMatricula`) se crearon con la cláusula `WITH EXECUTE AS OWNER`. Esto significa que, aunque el promotor y el coordinador ejecutan el procedimiento, la operación se realiza con los permisos del dueño del procedimiento (administrador). El DML directo queda bloqueado por `DENY` a nivel de esquema.
