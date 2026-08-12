# Docker y Base de Datos — MatriculaCloud360

![Docker](https://img.shields.io/badge/Docker-Contenedorizado-2496ED?logo=docker&logoColor=white)
![SQL Server 2025](https://img.shields.io/badge/SQL%20Server-2025-red?logo=microsoftsqlserver&logoColor=white)
![SQLCMD](https://img.shields.io/badge/SQLCMD-Init%20Autom%C3%A1tico-2F855A)

## 1. 🔧 Requisitos previos

Antes de levantar el entorno local, asegúrate de contar con lo siguiente instalado y funcionando:

- **Docker Desktop** instalado y en ejecución.
- **Docker Compose** (incluido en Docker Desktop o como binario independiente).
- Un cliente de administración SQL: **Azure Data Studio** o **SQL Server Management Studio (SSMS)**.
- La variable de entorno `SA_PASSWORD` definida con una contraseña para el usuario `sa`.

Ejemplo en PowerShell:

```powershell
$env:SA_PASSWORD = "Admin2026"
```

## 2. 🗂️ Estructura del proyecto

La carpeta `docker/` concentra la configuración del entorno contenedorizado:

```text
docker/
├── docker-compose.yml    # Definición del servicio SQL Server 2025
├── .env                  # Variables de entorno locales
├── init/
│   ├── init.sql          # Script de inicialización que orquesta los DDL/DML
│   └── wait-for-sql.sh   # Utilidad que espera que el motor SQL esté listo
└── volumes/              # Persistencia de datos del contenedor
```

La base de datos y los objetos de dominio se inicializan automáticamente al levantar el contenedor, ejecutando los scripts en el siguiente orden:

```text
 1. sqlserver/ddl/01_database.sql
 2. sqlserver/ddl/02_schemas.sql
 3. sqlserver/ddl/03_tables.sql
 4. sqlserver/ddl/04_constraints.sql         ← Sprint 2
 5. sqlserver/dml/01_seed_data.sql
 6. sqlserver/dml/02_test_data.sql           ← Sprint 2
 7. programmability/functions/fn_*.sql       ← Sprint 2
 8. programmability/procedures/uxp_*.sql     ← Sprint 2
 9. programmability/views/vw_*.sql           ← Sprint 2
```
    ├── functions/
    │   └── fn_CalcularComision.sql  → Función para cálculo de comisiones
    ├── procedures/
    │   ├── uxp_RegistrarEstudiante.sql
    │   ├── uxp_ActualizarEstudiante.sql
    │   ├── uxp_EliminarEstudiante.sql
    │   ├── uxp_ListarEstudiantes.sql
    │   ├── uxp_ObtenerMatricula.sql
    │   └── uxp_RegistrarMatricula.sql
    └── views/
        ├── vw_Matriculas.sql
        └── vw_EstudiantesMatriculados.sql
```

## 3. 🚀 Puesta en marcha

### ▶️ Levantar el entorno

Desde la carpeta `docker/`, ejecuta:

```bash
docker-compose up
```

Si deseas levantarlo en segundo plano:

```bash
docker-compose up -d
```

### 📋 Verificar el estado

```bash
docker ps
```

Deberías ver el contenedor `sqlserver_matricula` con el puerto `1433` expuesto.

### 🧹 Detener y limpiar el entorno

Para apagar el contenedor y eliminar el volumen persistente (borrando todos los datos):

```bash
docker-compose down -v
```

## 4. 🧱 Detalles técnicos del contenedor

| Característica | Especificación |
|---|---|
| **Motor** | SQL Server 2025 (Enterprise Developer Edition) |
| **Nombre del contenedor** | `sqlserver_matricula` |
| **Puerto expuesto** | `1433:1433` |
| **Seguridad** | Autenticación `sa` vía variable de entorno `SA_PASSWORD` |
| **Persistencia** | Volumen `mssql_data` para datos del motor entre reinicios |
| **Red** | `sqlserver_network` (bridge interna) |
| **Shell de arranque** | `wait-for-sql.sh` → `init.sql` (orquesta DDL + DML) |

El contenedor arranca `sqlservr`, espera a que el motor responda mediante `wait-for-sql.sh` y luego ejecuta `sqlcmd` para procesar el script de inicialización que orquesta secuencialmente los archivos DDL y DML.

## 5. 🧭 Esquemas de la base de datos

La base **`MatriculaCloud360`** se organiza por dominio de negocio mediante estos esquemas:

### academico

Entidades del dominio académico:

| Tabla | Función |
|---|---|
| `branches` | Sedes o campus institucionales |
| `careers` | Carreras académicas con duración e inversión total |
| `teachers` | Docentes con especialidad y correo corporativo |
| `courses` | Cursos vinculados a un docente |
| `academic_periods` | Periodos académicos (fechas y estado activo) |
| `admission_campaigns` | Campañas de admisión con porcentaje de comisión |
| `career_courses` | Relación muchos-a-muchos entre carreras y cursos |

### operaciones

Entidades del dominio transaccional:

| Tabla | Función |
|---|---|
| `students` | Estudiantes con DNI y email únicos |
| `promoters` | Promotores vinculados a un usuario del sistema y una sede base |
| `enrollments` | Matrículas que vinculan estudiante, carrera, sede, promotor, periodo y campaña |

### seguridad

Entidades de control de acceso:

| Tabla | Función |
|---|---|
| `roles` | Catálogo de roles (Administrador, Coordinador Academico, Promotor) |
| `users` | Usuarios del sistema con credenciales y FK a roles |

### auditoria

Entidad de trazabilidad:

| Tabla | Función |
|---|---|
| `audit_logs` | Bitácora de operaciones sobre tablas críticas |

Esta separación por dominio mejora el orden del modelo, facilita el mantenimiento y hace más clara la evolución del negocio.

## 6. 📊 Resumen de tablas

| # | Esquema | Tabla | Tipo |
|---|---|---|---|
| 1 | `seguridad` | `roles` | Catálogo |
| 2 | `seguridad` | `users` | Maestro |
| 3 | `auditoria` | `audit_logs` | Bitácora |
| 4 | `academico` | `branches` | Catálogo |
| 5 | `academico` | `careers` | Catálogo |
| 6 | `academico` | `teachers` | Maestro |
| 7 | `academico` | `academic_periods` | Catálogo |
| 8 | `academico` | `admission_campaigns` | Catálogo |
| 9 | `academico` | `courses` | Maestro |
| 10 | `academico` | `career_courses` | Relacional |
| 11 | `operaciones` | `students` | Maestro |
| 12 | `operaciones` | `promoters` | Maestro |
| 13 | `operaciones` | `enrollments` | Transaccional |

## 7. 📁 DDL — Scripts de definición

Los scripts se ejecutan en orden numérico y son **idempotentes** (incluyen guards `IF NOT EXISTS` / `IF OBJECT_ID`...`IS NULL`):

1. **`01_database.sql`** — Crea `MatriculaCloud360` si no existe.
2. **`02_schemas.sql`** — Crea los 4 esquemas de dominio.
3. **`03_tables.sql`** — Crea las 13 tablas con IDENTITY, PKs, FKs, unique constraints y borrado lógico.

## 8. 📁 DML — Datos semilla

**`01_seed_data.sql`** inserta datos iniciales respetando el orden de dependencias:

- 3 roles + 5 usuarios del sistema
- 4 sedes, 4 carreras, 4 docentes
- 1 periodo académico activo + 1 campaña de admisión
- 6 cursos + 8 asignaciones carrera-curso
- 3 estudiantes + 3 promotores
- 1 registro de auditoría
- 4 matrículas de ejemplo en una transacción



---

*Entorno contenedorizado para MatriculaCloud360Enterprise — Sprint 1.*