/* CREACIÓN DE ESQUEMAS */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'academico')
	EXEC('CREATE SCHEMA academico');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'operaciones')
	EXEC('CREATE SCHEMA operaciones');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'seguridad')
	EXEC('CREATE SCHEMA seguridad');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'auditoria')
	EXEC('CREATE SCHEMA auditoria');
GO