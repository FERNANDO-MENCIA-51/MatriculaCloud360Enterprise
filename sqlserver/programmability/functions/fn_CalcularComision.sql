/* 
   FUNCION: fn_CalcularComision - Calcula comision del promotor
   Dependencias: operaciones.enrollments, academico.admission_campaigns */

USE MatriculaCloud360;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_CalcularComision
(
    @enrollment_id INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @commission DECIMAL(10,2);

    SELECT @commission = e.amount * (ac.commission_percentage / 100.0)
    FROM operaciones.enrollments e
    INNER JOIN academico.admission_campaigns ac ON e.campaign_id = ac.id
    WHERE e.id = @enrollment_id;

    RETURN ISNULL(@commission, 0.00);
END
GO


