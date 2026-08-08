use MatriculaCloud360;
go


/* TABLAS DE SEGURIDAD Y AUDITORÍA */

/* TABLE ROLES */
if object_id(N'seguridad.roles', N'U') is null
begin
	create table seguridad.roles(
		role_id int identity(1,1) primary key,
		role_name varchar(50) not null unique,
		deleted_at datetime null
	);
end
go

/* TABLE AUDIT_LOGS */
if object_id(N'auditoria.logs', N'U') is null
begin
	create table auditoria.logs(
		log_id int identity(1,1) primary key,
		table_name varchar(50) not null,
		operation varchar(10) not null,
		[system_user] varchar(100) not null,
		operation_date datetime default getdate(),
		record_id varchar(50) not null
	);
end
go

/* TABLAS BASE */


/* TABLE SEDE */
if object_id(N'academico.branches', N'U') is null
begin
	create table academico.branches (
		branch_code varchar(20) primary key,
		branch_name varchar(90),
		city varchar(90),
		deleted_at datetime null
	);
end
go
 
/* TABLE PROMOTERS */
if object_id(N'operaciones.promoters', N'U') is null
begin
	create table operaciones.promoters(
		dni char(8) primary key,
		full_name varchar(150),
		base_branch varchar(20),
		corporate_email varchar(90),
		branch_code varchar(20),
		deleted_at datetime null,
		constraint fk_promoters_branch foreign key (branch_code) references academico.branches(branch_code)
	);
end
go

/* TABLE CAREERS */
if object_id(N'academico.careers', N'U') is null
begin
	create table academico.careers(
		career_code varchar(20) primary key,
		career_name varchar(90),
		duration int,
		tuition_fee decimal(8,2),
		branch_code varchar(20),
		deleted_at datetime null,
		constraint fk_careers_branch foreign key (branch_code) references academico.branches(branch_code)
	);
end
go

/* TABLE COURSES */
if object_id(N'academico.courses', N'U') is null
begin
	create table academico.courses(
		course_code varchar(20) primary key,
		course_name varchar(90),
		credits int,
		branch_code varchar(20),
		deleted_at datetime null,
		constraint fk_courses_branch foreign key (branch_code) references academico.branches(branch_code)
	);
end
go

/* TABLE TEACHERS */
if object_id(N'academico.teachers', N'U') is null
begin
	create table academico.teachers(
		teacher_id int identity(1,1) primary key,
		full_name varchar(150),
		corporate_email varchar(90),
		specialty varchar(90),
		branch_code varchar(20),
		deleted_at datetime null,
		constraint fk_teachers_branch foreign key (branch_code) references academico.branches(branch_code)
	);
end
go

/* TABLE STUDENTS */
if object_id(N'operaciones.students', N'U') is null
begin
	create table operaciones.students(
		dni char(8) primary key,
		first_name varchar(90),
		last_name varchar(90),
		personal_email varchar(90),
		phone char(9),
		deleted_at datetime null
	);
end
go

/* TABLE ENROLLMENTS */
if object_id(N'operaciones.enrollments', N'U') is null
begin
	create table operaciones.enrollments(
		enrollment_id int primary key,
		amount decimal(8,2),
		student_dni char(8),
		career_code varchar(20),
		branch_code varchar(20),
		promoters_dni char(8),
		deleted_at datetime null,
		constraint fk_enrollments_student foreign key (student_dni) references operaciones.students(dni),
		constraint fk_enrollments_career foreign key (career_code) references academico.careers(career_code),
		constraint fk_enrollments_branch foreign key (branch_code) references academico.branches(branch_code),
		constraint fk_enrollments_promoter foreign key (promoters_dni) references operaciones.promoters(dni)
	);
end
go
