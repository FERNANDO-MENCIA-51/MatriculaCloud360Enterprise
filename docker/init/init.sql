-- Orquestador de Arranque: MatriculaCloud360 Enterprise


PRINT 'Verificando e inicializando el entorno de base de datos...';
GO

-- Verifica que la base de datos exista antes de crearla

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MatriculaCloud360')
BEGIN
    CREATE DATABASE MatriculaCloud360;
    PRINT 'Base de datos MatriculaCloud360 creada exitosamente.';
END
ELSE
BEGIN
    PRINT 'La base de datos MatriculaCloud360 ya existe.';
END
GO

USE MatriculaCloud360;
GO

PRINT 'Contenedor listo. Los objetos DDL y DML se gestionan desde los scripts estructurados.';
GO