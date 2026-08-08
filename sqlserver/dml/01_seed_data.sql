/* DATA ROLES */
if not exists (select 1 from seguridad.roles where role_name in ('Administrador', 'Coordinador Academico', 'Promotor'))
begin
    insert into seguridad.roles (role_name)
    values ('Administrador'), ('Coordinador Academico'), ('Promotor');
end
go

/* DATA AUDIT_LOGS */
if not exists (select 1 from auditoria.logs where table_name = 'operaciones.enrollments' and record_id = '10001')
begin
    insert into auditoria.logs (table_name, operation, [system_user], record_id)
    values ('operaciones.enrollments', 'INSERT', SYSTEM_USER, '10001');
end
go

/* DATA SEDE */
if not exists (select 1 from academico.branches where branch_code = 'SED-001')
begin
    insert into academico.branches (branch_code,branch_name,city)
    values ('SED-001','San Carlos','Chincha'),
    ('SED-002','Central','Cañete'),
    ('SED-003','Parque Empresarial','Ica'),
    ('SED-004','Miraflores','Lima');
end
go

/* DATA PROMOTERS */
if not exists (select 1 from operaciones.promoters where dni = '45889922')
begin
    insert into operaciones.promoters (dni,full_name,base_branch,corporate_email)
    values ('45889922','Carlos Mendoza','SED-001','cmendoza@edufuturo.edu.pe'),
    ('71223344','Lucia Ramirez','SED-003','lramirez@edufuturo.edu.pe'),
    ('42551188','Jorge Valladolid','SED-004','jvalladolid@udufuturo.edu.pe');
end
go

/* DATA CAREERS */
if not exists (select 1 from academico.careers where career_code = 'CAR-101')
begin
    insert into academico.careers(career_code,career_name,duration,tuition_fee,branch_code)
    values('CAR-101','Desarrollo de Software',6,12000,'SED-001'),
    ('CAR-102','Administración de Empresas',6,15000,'SED-001'),
    ('CAR-103','Marketing y Publicidad Digital',4,18000,'SED-001'),
    ('CAR-104','Animación Digital 3D',6,24000,'SED-001');
end
go

/* DATA COURSES */
if not exists (select 1 from academico.courses where course_code = 'C-001')
begin
    insert into academico.courses(course_code,course_name,credits,branch_code)
    values('C-001','Logica de Programacion',4,'SED-001'),
    ('C-002','Diseño de Base de Datos',3,'SED-002'),
    ('C-003','Contabilidad General',3,'SED-003'),
    ('C-004','Comportamiento del Consumidor',3,'SED-004'),
    ('C-005','Modelado 3D Basico',4,'SED-001'),
    ('C-006','Etica Profesional',2,'SED-002');
end
go

/* DATA TEACHERS */
if not exists (select 1 from academico.teachers where corporate_email = 'aturing@edufuturo.edu.pe')
begin
    insert into academico.teachers(full_name,corporate_email,specialty,branch_code)
    values('Alan Turing','aturing@edufuturo.edu.pe','Ingenieria de Software','SED-001'),
    ('Philip Kotler','pkotler@edufuturo.edu.pe','Marketing y Ventas','SED-002'),
    ('Peter Drucker','pdrucker@edufuturo.edu.pe','Gestion Empresarial','SED-003'),
    ('Ed Catmull','ecatmull@edufuturo.edu.pe','Animación y VFX','SED-004');
end
go

/* DATA STUDENTS */
if not exists (select 1 from operaciones.students where dni = '75112233')
begin
    insert into operaciones.students(dni,first_name,last_name,personal_email,phone)
    values('75112233','Ana maría','Pérez Gómez','ana.perez@gmail.com','987654321'),
    ('48996655','Luis Felipe','Torres Rivas','luisf.torres@outlook.com','912345678'),
    ('70114477','Carmen','Rojas Silva','crojas_99@yahoo.com','945612378');
end
go

/* TRANSACCIÓN PARA MATRÍCULAS*/
if not exists (select 1 from operaciones.enrollments where enrollment_id = 10001)
begin
    begin try
        begin transaction;
        insert into operaciones.enrollments(enrollment_id,student_dni,career_code,branch_code,promoters_dni,amount)
        values (10001,'75112233','CAR-101','SED-001','45889922',4500),
         (10002,'48996655','CAR-104','SED-003','71223344',4800), 
         (10003,'70114477','CAR-103','SED-004','42551188',3200), 
         (10004,'75112233','CAR-102','SED-001','45889922',3800);
        commit transaction;
    end try
    begin catch
        rollback transaction;
        print 'Error: La transacción de matrícula falló y fue revertida.';
    end catch;
end
go
