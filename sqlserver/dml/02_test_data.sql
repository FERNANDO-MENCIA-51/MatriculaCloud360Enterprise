/*  SCRIPT DML - 02: Datos de Prueba (Test Data) */

USE MatriculaCloud360;
GO


-- ESQUEMA: academico - Nuevos Catalogos


/* DATA: academico.academic_periods - Nuevos periodos */
IF NOT EXISTS (SELECT 1 FROM academico.academic_periods WHERE name = '2025-II')
BEGIN
    INSERT INTO academico.academic_periods (name, start_date, end_date, is_active)
    VALUES ('2025-II', '2025-09-01', '2026-02-28', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM academico.academic_periods WHERE name = '2026-I')
BEGIN
    INSERT INTO academico.academic_periods (name, start_date, end_date, is_active)
    VALUES ('2026-I', '2026-03-01', '2026-08-31', 1);
END
GO

/* DATA: academico.admission_campaigns - Nuevas campanas */
IF NOT EXISTS (SELECT 1 FROM academico.admission_campaigns WHERE name = 'Admision 2025-II')
BEGIN
    INSERT INTO academico.admission_campaigns (name, commission_percentage, is_active)
    VALUES ('Admision 2025-II', 7.50, 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM academico.admission_campaigns WHERE name = 'Admision 2026-I')
BEGIN
    INSERT INTO academico.admission_campaigns (name, commission_percentage, is_active)
    VALUES ('Admision 2026-I', 6.00, 1);
END
GO

-- ESQUEMA: operaciones - Nuevos Estudiantes


/* DATA: operaciones.students - 8 estudiantes adicionales */
IF NOT EXISTS (SELECT 1 FROM operaciones.students WHERE dni = '83445566')
BEGIN
    INSERT INTO operaciones.students (dni, first_name, last_name, personal_email, phone)
    VALUES
        ('83445566', 'Diego',   'Martinez Lopez',    'diego.martinez@gmail.com',     '998877665'),
        ('77223344', 'Sofia',   'Gutierrez Ramos',   'sofia.gutierrez@outlook.com',  '987654322'),
        ('65881122', 'Mateo',   'Castro Huaman',     'mateo.castro@yahoo.com',       '976543210'),
        ('90112233', 'Valeria', 'Paredes Quispe',    'valeria.paredes@gmail.com',    '965432109'),
        ('51336677', 'Gabriel', 'Fernandez Silva',   'gabriel.fernandez@outlook.com','954321098'),
        ('60442211', 'Rodrigo', 'Quispe Mamani',     'rodrigo.qm@gmail.com',         '987651234'),
        ('78839900', 'Camila',  'Huaman Rios',       'camila.huaman@outlook.com',    '976543211'),
        ('63557788', 'Renato',  'Pizarro Flores',    'renato.pf@yahoo.com',          '965432100');
END
GO


-- TRANSACCION: Nuevas Matriculas de Prueba

IF NOT EXISTS (SELECT 1 FROM operaciones.enrollments WHERE enrollment_code = 'MAT-10005')
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO operaciones.enrollments (
            enrollment_code, student_id, career_id, branch_id,
            promoter_id, period_id, campaign_id, amount
        )
        VALUES
            -- Diego -> Desarrollo Software, Central, Carlos Mendoza
            ('MAT-10005', 4, 1, 2, 1, 2, 2, 4500.00),
            -- Sofia -> Marketing, Parque Empresarial, Lucia Ramirez
            ('MAT-10006', 5, 3, 3, 2, 2, 2, 3200.00),
            -- Mateo -> Administracion, San Carlos, Carlos Mendoza
            ('MAT-10007', 6, 2, 1, 1, 1, 2, 5000.00),
            -- Valeria -> Animacion 3D, Miraflores, Jorge Valladolid
            ('MAT-10008', 7, 4, 4, 3, 2, 1, 4800.00),
            -- Gabriel -> Desarrollo Software, Central, Carlos Mendoza
            ('MAT-10009', 8, 1, 2, 1, 1, 1, 4500.00),
            -- Rodrigo -> Desarrollo Software, Central, Carlos Mendoza
            ('MAT-10010', 9, 1, 2, 1, 3, 3, 4500.00),
            -- Camila -> Marketing, Parque Empresarial, Lucia Ramirez
            ('MAT-10011', 10, 3, 3, 2, 3, 3, 3200.00),
            -- Renato -> Animacion 3D, Miraflores, Jorge Valladolid
            ('MAT-10012', 11, 4, 4, 3, 2, 2, 4800.00);

        INSERT INTO auditoria.audit_logs (user_id, table_name, operation)
        VALUES (1, 'operaciones.enrollments', 'INSERT');

        COMMIT TRANSACTION;
        PRINT 'Datos de prueba insertados exitosamente.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: La transaccion de datos de prueba fallo y fue revertida.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END
GO