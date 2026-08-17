# Testing

Documentación de las pruebas automatizadas del proyecto: suites, objetivos, cómo ejecutarlas y cómo interpretar los resultados.

---

## 1. Resumen

| Suite | Pruebas | Objetivo |
|---|---|---|
| Funcional | T1-T17 | Validar CRUD, soft-delete, auditoría, reglas de matrícula, vistas y consultas analíticas |
| Seguridad | S1-S15 | Validar que cada rol solo ejecuta las operaciones autorizadas |
| Recuperación | R1-R3 | Validar respaldo FULL, restauración e integridad física/lógica |
| **Total** | **35** | **35/35 PASS** |

---

## 2. Pruebas funcionales (T1-T17)

| ID | Nombre | Descripción |
|---|---|---|
| T1 | Registrar estudiante | Inserta un estudiante válido y confirma que existe |
| T2 | Rechazar DNI duplicado | Intenta registrar un DNI ya existente; debe fallar |
| T3 | Rechazar email duplicado | Intenta registrar un email ya existente; debe fallar |
| T4 | Actualizar estudiante | Modifica datos y confirma el cambio |
| T5 | Soft-delete vía procedimiento | Elimina un estudiante con `usp_EliminarEstudiante` y verifica `deleted_at` |
| T6 | DELETE físico → soft-delete | Ejecuta `DELETE` directo y confirma que el trigger convierte en `UPDATE deleted_at` |
| T7 | Auditoría INSERT/UPDATE/DELETE | Verifica que cada operación generó registros en `auditoria.audit_logs` |
| T8 | Registrar matrícula válida | Registra una matrícula con datos válidos |
| T9 | Rechazar promotor de otra sede | Intenta matricular con un promotor que no pertenece a la sede; debe fallar |
| T10 | Rechazar periodo inactivo | Intenta matricular en un periodo con `is_active = 0`; debe fallar |
| T11 | Rechazar monto <= 0 | Intenta matricular con monto cero; debe fallar |
| T12 | Obtener detalle de matrícula | Ejecuta `usp_ObtenerMatricula` y confirma que devuelve datos |
| T13 | Listar excluye eliminados | Ejecuta `usp_ListarEstudiantes` y verifica que no aparecen soft-deleted |
| T14 | fn_CalcularComision | Calcula la comisión de una matrícula y compara con el valor esperado |
| T15 | Vistas operativas | Confirma que `vw_Matriculas` y `vw_EstudiantesMatriculados` tienen datos |
| T16 | Consultas analíticas | Ejecuta CTEs, funciones de ventana y agregados sin errores |
| T17 | Soft-delete en catálogos | Elimina una sede con `DELETE` directo y confirma borrado lógico |

---

## 3. Pruebas de seguridad (S1-S15)

| ID | Nombre | Descripción |
|---|---|---|
| S1 | Promotor: SELECT vw_Matriculas | Verifica acceso permitido |
| S2 | Promotor: SELECT estudiantes | Verifica acceso permitido |
| S3 | Promotor: EXEC usp_RegistrarMatricula | Verifica acceso permitido |
| S4 | Promotor: SELECT seguridad.users | Verifica acceso denegado |
| S5 | Promotor: SELECT auditoria.audit_logs | Verifica acceso denegado |
| S6 | Promotor: SELECT vw_EstudiantesMatriculados | Verifica acceso denegado |
| S7 | Promotor: DELETE estudiantes | Verifica acceso denegado |
| S8 | Coordinador: SELECT vw_EstudiantesMatriculados | Verifica acceso permitido |
| S9 | Coordinador: SELECT auditoria.audit_logs | Verifica acceso permitido |
| S10 | Coordinador: SELECT seguridad.users | Verifica acceso denegado |
| S11 | Coordinador: DELETE matrículas | Verifica acceso denegado |
| S12 | Coordinador: EXEC usp_RegistrarEstudiante | Verifica acceso permitido |
| S13 | Administrador: SELECT seguridad | Verifica acceso permitido |
| S14 | Administrador: DELETE matrículas | Verifica acceso permitido |
| S15 | Administrador: EXEC usp_RegistrarEstudiante | Verifica acceso permitido |

---

## 4. Pruebas de recuperación (R1-R3)

| ID | Nombre | Descripción |
|---|---|---|
| R1 | Marcador eliminado por restore | Confirma que el registro posterior al respaldo desaparece tras la restauración |
| R2 | Datos conservados tras restore | Confirma que la información del momento del respaldo se conserva |
| R3 | Integridad tras restore | Ejecuta `DBCC CHECKDB` y confirma que no hay errores |

---

## 5. Cómo ejecutar las pruebas

### Automáticamente (recomendado)

Las pruebas se ejecutan automáticamente al final de la inicialización con `docker compose up`. Los resultados se guardan en `testing.test_results`.

### Manualmente

Conéctate con `sa` / `Admin2026` y ejecuta los archivos en orden:

```sql
-- Pruebas funcionales
:r sqlserver/testing/functional_tests.sql

-- Pruebas de seguridad
:r sqlserver/testing/security_tests.sql

-- Pruebas de recuperación
:r sqlserver/testing/recovery_tests.sql
```

### Ver resultados

```sql
-- Resumen por suite
SELECT category AS suite,
       COUNT(*) AS pruebas,
       SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS pasaron,
       SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END) AS fallaron
FROM testing.test_results
GROUP BY category;

-- Detalle de cada prueba
SELECT test_name, category, result, detail
FROM testing.test_results
ORDER BY category, test_name;
```

---

## 6. Interpretación de resultados

- **PASS**: La prueba cumplió con el comportamiento esperado.
- **FAIL**: La prueba no cumplió. Revisa el mensaje de error en la columna `detail`.

Si alguna prueba falla, verifica:

1. Que el contenedor esté corriendo (`docker ps`).
2. Que la inicialización haya terminado sin errores (`docker logs sqlserver_matricula`).
3. Que no haya datos corruptos (reinicia con `down -v` y `up -d`).
