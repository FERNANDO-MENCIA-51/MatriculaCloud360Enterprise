# Docker y Base de Datos

![Docker](https://img.shields.io/badge/Docker-Contenedorizado-2496ED?logo=docker&logoColor=white)
![SQL Server 2025](https://img.shields.io/badge/SQL%20Server-2025-red?logo=microsoftsqlserver&logoColor=white)
![SQLCMD](https://img.shields.io/badge/SQLCMD-Init%20Autom%C3%A1tico-2F855A)

## 1. 🔧 Requisitos previos

Antes de levantar el entorno local, asegúrate de contar con lo siguiente instalado y funcionando:

- Docker Desktop.
- Docker Compose.
- Un cliente de administración SQL como Azure Data Studio o SQL Server Management Studio.
- Una variable de entorno `SA_PASSWORD` definida con una contraseña válida para `sa`.

Ejemplo en PowerShell:

```powershell
$env:SA_PASSWORD = "Admin2026"
```

## 2. 🗂️ Estructura del proyecto

La carpeta `docker/` concentra la configuración del entorno contenedorizado:

- `docker-compose.yml`: define el servicio de SQL Server 2025, el puerto publicado y el volumen persistente.
- `init/`: contiene el script de arranque `init.sql` y utilidades de inicialización.
- `volumes/`: carpeta destinada a persistencia y soporte del almacenamiento local.

La base de datos y los objetos de dominio se inicializan automáticamente al levantar el contenedor, ejecutando los scripts ubicados en `sqlserver/`.

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

### 🧹 Detener y limpiar el entorno

Para apagar el contenedor y eliminar también el volumen persistente:

```bash
docker-compose down -v
```

## 4. 🧱 Detalles técnicos del contenedor

- Motor: SQL Server 2025 (Enterprise Developer Edition).
- Contenedor: `sqlserver_matricula`.
- Puerto expuesto: `1433:1433`.
- Seguridad: la autenticación de `sa` se controla con la variable de entorno `SA_PASSWORD`.
- Persistencia: el volumen `mssql_data` mantiene los datos del motor entre reinicios.

El contenedor arranca `sqlservr`, espera a que el motor responda y luego ejecuta `sqlcmd` para procesar el script de inicialización y la carga estructurada de la base de datos.

## 5. 🧭 Esquemas de la base de datos

La base `MatriculaCloud360` se organiza por contexto de negocio mediante estos esquemas:

- `academico`: entidades académicas como sedes, carreras, cursos y docentes.
- `operaciones`: entidades transaccionales como estudiantes, promotores y matrículas.
- `seguridad`: catálogos de control de acceso, como roles.
- `auditoria`: bitácora de operaciones para trazabilidad y seguimiento.

Esta separación mejora el orden del modelo, facilita el mantenimiento y hace más clara la evolución del dominio.

