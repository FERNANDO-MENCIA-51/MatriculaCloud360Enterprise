# Arquitectura del proyecto

Documentación técnica completa de la base de datos MatriculaCloud360: esquemas, tablas, programmability, auditoría, optimización, seguridad, mantenimiento y testing.

---

## 1. Esquemas

| Esquema | Dominio | Contenido |
|---|---|---|
| `seguridad` | Control de acceso | roles, users |
| `academico` | Oferta académica | branches, careers, courses, teachers, periods, campaigns, career_courses |
| `operaciones` | Procesos transaccionales | students, promoters, enrollments |
| `auditoria` | Trazabilidad | audit_logs, maintenance_log |
| `optimizacion` | Evidencia de rendimiento | performance_results |
| `testing` | Pruebas automatizadas | test_results |

---

## 2. Tablas

### 2.1 academico

| Tabla | Descripción |
|---|---|
| `branches` | Sedes o campus institucionales (`code`, `name`, `city`) |
| `careers` | Carreras académicas (`code`, `name`, `duration_cycles`, `total_investment`) |
| `teachers` | Docentes con especialidad y correo corporativo |
| `courses` | Cursos asociados a un docente (`teacher_id`) |
| `academic_periods` | Periodos académicos (`name`, `start_date`, `end_date`, `is_active`) |
| `admission_campaigns` | Campañas de admisión con porcentaje de comisión |
| `career_courses` | Relación N:M entre carreras y cursos |

### 2.2 operaciones

| Tabla | Descripción |
|---|---|
| `students` | Estudiantes con `dni` y `personal_email` únicos |
| `promoters` | Promotores vinculados a un usuario del sistema y a una sede base |
| `enrollments` | Matrículas que vinculan estudiante, carrera, sede, promotor, periodo y campaña |

### 2.3 seguridad

| Tabla | Descripción |
|---|---|
| `roles` | Catálogo de roles (Administrador, Coordinador Académico, Promotor) |
| `users` | Usuarios del sistema con `username` único y `password_hash` |

### 2.4 auditoria

| Tabla | Descripción |
|---|---|
| `audit_logs` | Bitácora de INSERT/UPDATE/DELETE sobre tablas críticas (quién, cuándo, qué, old_data, new_data) |
| `maintenance_log` | Bitácora de respaldos y mantenimiento de índices |

---

## 3. Programabilidad (Sprint 2 + Sprint 3)

### 3.1 Función

| Objeto | Descripción |
|---|---|
| `fn_CalcularComision` | Comisión del promotor: `amount x (commission_percentage / 100)` |

### 3.2 Procedimientos almacenados

| Procedimiento | Descripción |
|---|---|
| `usp_RegistrarEstudiante` | Registra un estudiante validando DNI y email únicos |
| `usp_ActualizarEstudiante` | Actualiza los datos de un estudiante |
| `usp_EliminarEstudiante` | Eliminación lógica (soft-delete) de un estudiante |
| `usp_ListarEstudiantes` | Lista estudiantes con filtro opcional de eliminados |
| `usp_ObtenerMatricula` | Obtiene el detalle completo de una matrícula |
| `usp_RegistrarMatricula` | Registra una matrícula con validación cruzada y transacción |

### 3.3 Vistas

| Objeto | Descripción |
|---|---|
| `vw_Matriculas` | Matrículas con estudiante, carrera, sede, promotor, periodo, campaña, monto y comisión |
| `vw_EstudiantesMatriculados` | Estudiantes con total de matrículas, inversión acumulada y última fecha |

---

## 4. Auditoría (Sprint 3)

La tabla `auditoria.audit_logs` fue ampliada con las columnas:

- `record_id`: id del registro afectado.
- `old_data`: valor anterior en formato JSON.
- `new_data`: valor nuevo en formato JSON.
- `executed_by`: usuario de SQL Server que ejecutó la acción.

### Triggers implementados

| Tabla | Triggers |
|---|---|
| `operaciones.students` | INSTEAD OF DELETE (soft-delete) + AFTER INSERT/UPDATE/DELETE (auditoría) |
| `operaciones.promoters` | INSTEAD OF DELETE (soft-delete) + AFTER INSERT/UPDATE/DELETE (auditoría) |
| `operaciones.enrollments` | AFTER INSERT/UPDATE/DELETE (auditoría) |
| `seguridad.users` | AFTER INSERT/UPDATE/DELETE (auditoría) |
| `academico.branches` | INSTEAD OF DELETE (soft-delete) |
| `academico.careers` | INSTEAD OF DELETE (soft-delete) |
| `academico.teachers` | INSTEAD OF DELETE (soft-delete) |
| `academico.courses` | INSTEAD OF DELETE (soft-delete) |

> **Total: 18 triggers.**

Cuando se ejecuta un `DELETE` sobre una tabla con soft-delete, el trigger `INSTEAD OF DELETE` convierte la operación en un `UPDATE deleted_at = GETDATE()`. El trigger `AFTER UPDATE` detecta este cambio y registra la operación como `DELETE` en la bitácora, manteniendo la auditoría intacta.

---

## 5. Optimización (Sprint 3)

### 5.1 Índices implementados

| Índice | Tabla | Descripción |
|---|---|---|
| `IX_enrollments_student_id` | `operaciones.enrollments` | JOIN por `student_id` |
| `IX_enrollments_career_id` | `operaciones.enrollments` | Filtros y agrupaciones por carrera |
| `IX_enrollments_branch_id` | `operaciones.enrollments` | Análisis por sede |
| `IX_enrollments_promoter_campaign_cover` | `operaciones.enrollments` | Cobertura para comisiones por promotor/campaña |
| `IX_enrollments_period_id` | `operaciones.enrollments` | Consultas por periodo académico |
| `IX_enrollments_campaign_id` | `operaciones.enrollments` | Consultas por campaña |
| `IX_enrollments_enrollment_date` | `operaciones.enrollments` | Series temporales y rangos de fecha |
| `IX_enrollments_student_cover` | `operaciones.enrollments` | Cobertura para `vw_EstudiantesMatriculados` |
| `IX_students_active_filtered` | `operaciones.students` | Filtrado: estudiantes activos (`deleted_at IS NULL`) |
| `IX_promoters_base_branch` | `operaciones.promoters` | Validación promotor-sede |
| `IX_campaigns_active_filtered` | `academico.admission_campaigns` | Filtrado: campañas activas |
| `IX_periods_active_filtered` | `academico.academic_periods` | Filtrado: periodos activos |
| `IX_audit_logs_table_action` | `auditoria.audit_logs` | Consultas de auditoría por tabla y fecha |

### 5.2 Consultas analíticas

| Consulta | Técnica |
|---|---|
| Q1 - Matrícula detallada | JOINs + función `fn_CalcularComision` |
| Q2 - Comisiones por promotor | CTE + `RANK` |
| Q3 - Serie temporal por periodo | CTE + `LAG` |
| Q4 - Estudiantes matriculados | CTE + agregados |
| Q5 - Matrículas por sede y carrera | `GROUP BY ROLLUP` |
| Indicadores institucionales | CTE + agregados (KPIs + montos) |
| Participación por campaña | CTE + `SUM OVER` |
| Promedio móvil (3 matrículas) | `AVG OVER` con ventana de filas |
| Matrícula vs promedio de carrera | Subconsulta correlacionada |

---

## 6. Seguridad (Sprint 3)

### Roles

| Rol | Usuario | Alcance |
|---|---|---|
| `RolAdministrador` | `usuario_admin` | Acceso total |
| `RolCoordinadorAcademico` | `usuario_coordinador` | Lectura académica/operativa + auditoría |
| `RolPromotor` | `usuario_promotor` | Solo matrículas y consultas operativas |

### Estrategia

- Logins y usuarios creados a nivel de servidor y base de datos.
- Permisos aplicados con `GRANT`, `DENY` y `REVOKE`.
- Procedimientos de escritura con `WITH EXECUTE AS OWNER`.
- Pruebas de seguridad con `EXECUTE AS USER` (S1-S15).

---

## 7. Mantenimiento (Sprint 3)

### Procedimientos

| Procedimiento | Función |
|---|---|
| `usp_BackupDatabaseFull` | Respaldo FULL diario |
| `usp_BackupDatabaseDifferential` | Respaldo DIFERENCIAL cada 6 horas |
| `usp_BackupDatabaseLog` | Respaldo de LOG cada hora |
| `usp_RestoreDatabaseFull` | Restauración de respaldo FULL |
| `usp_RestoreDatabaseDiff` | Restauración FULL + DIFERENCIAL |
| `usp_RestoreDatabaseWithLog` | Restauración FULL + LOG(s) |
| `usp_MaintenanceIndexes` | REBUILD / REORGANIZE según fragmentación |
| `usp_CheckDatabaseIntegrity` | DBCC CHECKDB |

Cada ejecución queda registrada en `auditoria.maintenance_log`.

---

## 8. Testing (Sprint 3)

| Suite | Pruebas | Resultado |
|---|---|---|
| Funcional | T1-T17 | 17/17 PASS |
| Seguridad | S1-S15 | 15/15 PASS |
| Recuperación | R1-R3 | 3/3 PASS |
| **Total** | **35** | **35/35 PASS** |

Las pruebas se ejecutan automáticamente al final de la inicialización y los resultados se guardan en `testing.test_results`.
