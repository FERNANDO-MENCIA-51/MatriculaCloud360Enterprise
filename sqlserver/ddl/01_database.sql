/* Creación de la Base de Datos */

IF DB_ID(N'MatriculaCloud360') IS NULL
BEGIN
    CREATE DATABASE MatriculaCloud360;
END
GO

USE MatriculaCloud360;
GO
