-- ============================================================
-- UPTM Digital - Script Completo para Somee (SQL Server)
-- Crea TODAS las tablas desde cero + datos iniciales
-- Generado: 2026-03-02
-- ============================================================

-- ==========================================
-- 1. TABLA DE MIGRACIONES EF CORE
-- ==========================================
IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

-- ==========================================
-- 2. TABLAS INDEPENDIENTES (sin FK)
-- ==========================================

-- Rol
CREATE TABLE [Rol] (
    [IdRol] int NOT NULL IDENTITY,
    [NombreRol] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Rol] PRIMARY KEY ([IdRol])
);
GO

-- Carrera
CREATE TABLE [Carrera] (
    [IdCarrera] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Carrera] PRIMARY KEY ([IdCarrera])
);
GO

-- Semestre
CREATE TABLE [Semestre] (
    [IdSemestre] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Semestre] PRIMARY KEY ([IdSemestre])
);
GO

-- Periodo
CREATE TABLE [Periodo] (
    [IdPeriodo] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    [Activo] bit NOT NULL,
    CONSTRAINT [PK_Periodo] PRIMARY KEY ([IdPeriodo])
);
GO

-- Anuncio
CREATE TABLE [Anuncio] (
    [IdAnuncio] int NOT NULL IDENTITY,
    [Titulo] nvarchar(max) NOT NULL,
    [Contenido] nvarchar(max) NOT NULL,
    [FechaPublicacion] datetime2 NOT NULL,
    [Autor] nvarchar(max) NULL,
    CONSTRAINT [PK_Anuncio] PRIMARY KEY ([IdAnuncio])
);
GO

-- RegistroInstitucional (Base Maestro / Nómina)
CREATE TABLE [RegistroInstitucional] (
    [Id] int NOT NULL IDENTITY,
    [Cedula] nvarchar(max) NOT NULL,
    [Nombres] nvarchar(max) NOT NULL,
    [Apellidos] nvarchar(max) NOT NULL,
    [CarreraDepartamento] nvarchar(max) NOT NULL,
    [RolEsperado] nvarchar(max) NOT NULL,
    [CorreoInstitucional] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_RegistroInstitucional] PRIMARY KEY ([Id])
);
GO

-- ControlAcceso
CREATE TABLE [ControlAcceso] (
    [Id] int NOT NULL IDENTITY,
    [Cedula] nvarchar(20) NOT NULL,
    [PersonalSeguridadId] int NULL,
    [FechaHora] datetime2 NOT NULL,
    [Tipo] nvarchar(10) NOT NULL,
    [Ubicacion] nvarchar(50) NULL,
    CONSTRAINT [PK_ControlAcceso] PRIMARY KEY ([Id])
);
GO

-- Estudiante
CREATE TABLE [Estudiante] (
    [IdEstudiante] int NOT NULL IDENTITY,
    [Cedula] nvarchar(max) NOT NULL,
    [Nombres] nvarchar(max) NOT NULL,
    [Apellidos] nvarchar(max) NOT NULL,
    [CorreoInstitucional] nvarchar(max) NULL,
    [CodAlumno] nvarchar(max) NULL,
    [CodCarrera] nvarchar(max) NULL,
    [Carrera] nvarchar(max) NULL,
    [Direccion] nvarchar(max) NULL,
    [Telefono] nvarchar(max) NULL,
    [FechaRegistro] datetime2 NULL,
    [UsuarioLogin] nvarchar(max) NULL,
    CONSTRAINT [PK_Estudiante] PRIMARY KEY ([IdEstudiante])
);
GO

-- Profesor
CREATE TABLE [Profesor] (
    [IdProfesor] int NOT NULL IDENTITY,
    [Cedula] nvarchar(max) NOT NULL,
    [Nombres] nvarchar(max) NOT NULL,
    [Apellidos] nvarchar(max) NOT NULL,
    [CorreoInstitucional] nvarchar(max) NULL,
    [CodProfesor] nvarchar(max) NULL,
    [Departamento] nvarchar(max) NULL,
    [Telefono] nvarchar(max) NULL,
    [UsuarioLogin] nvarchar(max) NULL,
    CONSTRAINT [PK_Profesor] PRIMARY KEY ([IdProfesor])
);
GO

-- ==========================================
-- 3. TABLAS CON FK (dependientes)
-- ==========================================

-- Usuario (FK -> Rol)
CREATE TABLE [Usuario] (
    [IdUsuario] int NOT NULL IDENTITY,
    [NombreUsuario] nvarchar(max) NOT NULL,
    [ContrasenaHash] nvarchar(max) NOT NULL,
    [Cedula] nvarchar(max) NULL,
    [RolId] int NOT NULL,
    [EstadoCuenta] bit NOT NULL,
    [UltimoAcceso] datetime2 NULL,
    CONSTRAINT [PK_Usuario] PRIMARY KEY ([IdUsuario]),
    CONSTRAINT [FK_Usuario_Rol_RolId] FOREIGN KEY ([RolId]) REFERENCES [Rol] ([IdRol]) ON DELETE CASCADE
);
GO

-- Asignatura (FK -> Profesor)
CREATE TABLE [Asignatura] (
    [IdAsignatura] int NOT NULL IDENTITY,
    [Codigo] nvarchar(max) NOT NULL,
    [Nombre] nvarchar(max) NOT NULL,
    [Creditos] int NOT NULL,
    [Semestre] int NULL,
    [Departamento] nvarchar(max) NULL,
    [ProfesorId] int NULL,
    CONSTRAINT [PK_Asignatura] PRIMARY KEY ([IdAsignatura]),
    CONSTRAINT [FK_Asignatura_Profesor_ProfesorId] FOREIGN KEY ([ProfesorId]) REFERENCES [Profesor] ([IdProfesor])
);
GO

-- Horarios (FK -> Asignatura via AsignaturaId)
CREATE TABLE [Horarios] (
    [IdHorario] int NOT NULL IDENTITY,
    [AsignaturaId] int NOT NULL,
    [Dia] nvarchar(max) NOT NULL,
    [HoraInicio] nvarchar(max) NOT NULL,
    [HoraFin] nvarchar(max) NOT NULL,
    [Aula] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Horarios] PRIMARY KEY ([IdHorario])
);
GO

-- Mensaje
CREATE TABLE [Mensaje] (
    [IdMensaje] int NOT NULL IDENTITY,
    [AsignaturaId] int NOT NULL,
    [Contenido] nvarchar(max) NOT NULL,
    [FechaEnvio] datetime2 NOT NULL,
    [EmisorNombre] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Mensaje] PRIMARY KEY ([IdMensaje])
);
GO

-- Constancia (FK -> Estudiante)
CREATE TABLE [Constancia] (
    [IdConstancia] int NOT NULL IDENTITY,
    [EstudianteId] int NOT NULL,
    [TipoConstancia] nvarchar(max) NOT NULL,
    [Estado] nvarchar(max) NULL,
    [FechaSolicitud] datetime2 NULL,
    [CodigoQR] nvarchar(max) NULL,
    [ArchivoUrl] nvarchar(max) NULL,
    CONSTRAINT [PK_Constancia] PRIMARY KEY ([IdConstancia]),
    CONSTRAINT [FK_Constancia_Estudiante_EstudianteId] FOREIGN KEY ([EstudianteId]) REFERENCES [Estudiante] ([IdEstudiante]) ON DELETE CASCADE
);
GO

-- Inscripcion (FK -> Estudiante, Asignatura)
CREATE TABLE [Inscripcion] (
    [IdInscripcion] int NOT NULL IDENTITY,
    [EstudianteId] int NOT NULL,
    [AsignaturaId] int NOT NULL,
    [Periodo] nvarchar(max) NOT NULL,
    [FechaInscripcion] datetime2 NULL,
    [Estado] nvarchar(max) NULL,
    CONSTRAINT [PK_Inscripcion] PRIMARY KEY ([IdInscripcion]),
    CONSTRAINT [FK_Inscripcion_Estudiante_EstudianteId] FOREIGN KEY ([EstudianteId]) REFERENCES [Estudiante] ([IdEstudiante]) ON DELETE CASCADE,
    CONSTRAINT [FK_Inscripcion_Asignatura_AsignaturaId] FOREIGN KEY ([AsignaturaId]) REFERENCES [Asignatura] ([IdAsignatura]) ON DELETE CASCADE
);
GO

-- Nota (FK -> Asignatura, Estudiante, Profesor)
CREATE TABLE [Nota] (
    [IdNota] int NOT NULL IDENTITY,
    [AsignaturaId] int NOT NULL,
    [EstudianteId] int NOT NULL,
    [Calificacion] decimal(18,2) NULL,
    [Fecha] datetime2 NULL,
    [ProfesorId] int NULL,
    [CodigoQR] nvarchar(max) NULL,
    CONSTRAINT [PK_Nota] PRIMARY KEY ([IdNota]),
    CONSTRAINT [FK_Nota_Asignatura_AsignaturaId] FOREIGN KEY ([AsignaturaId]) REFERENCES [Asignatura] ([IdAsignatura]) ON DELETE CASCADE,
    CONSTRAINT [FK_Nota_Estudiante_EstudianteId] FOREIGN KEY ([EstudianteId]) REFERENCES [Estudiante] ([IdEstudiante]) ON DELETE CASCADE,
    CONSTRAINT [FK_Nota_Profesor_ProfesorId] FOREIGN KEY ([ProfesorId]) REFERENCES [Profesor] ([IdProfesor])
);
GO

-- Asistencia (FK -> Asignatura, Estudiante, Profesor)
CREATE TABLE [Asistencia] (
    [IdAsistencia] int NOT NULL IDENTITY,
    [AsignaturaId] int NOT NULL,
    [EstudianteId] int NOT NULL,
    [Fecha] datetime2 NOT NULL,
    [Estado] nvarchar(max) NOT NULL,
    [CodigoQR] nvarchar(max) NULL,
    [ProfesorId] int NULL,
    CONSTRAINT [PK_Asistencia] PRIMARY KEY ([IdAsistencia]),
    CONSTRAINT [FK_Asistencia_Asignatura_AsignaturaId] FOREIGN KEY ([AsignaturaId]) REFERENCES [Asignatura] ([IdAsignatura]) ON DELETE CASCADE,
    CONSTRAINT [FK_Asistencia_Estudiante_EstudianteId] FOREIGN KEY ([EstudianteId]) REFERENCES [Estudiante] ([IdEstudiante]) ON DELETE CASCADE,
    CONSTRAINT [FK_Asistencia_Profesor_ProfesorId] FOREIGN KEY ([ProfesorId]) REFERENCES [Profesor] ([IdProfesor])
);
GO

-- ==========================================
-- 4. INDICES
-- ==========================================
CREATE INDEX [IX_Usuario_RolId] ON [Usuario] ([RolId]);
GO
CREATE INDEX [IX_Asignatura_ProfesorId] ON [Asignatura] ([ProfesorId]);
GO
CREATE INDEX [IX_Constancia_EstudianteId] ON [Constancia] ([EstudianteId]);
GO
CREATE INDEX [IX_Inscripcion_EstudianteId] ON [Inscripcion] ([EstudianteId]);
GO
CREATE INDEX [IX_Inscripcion_AsignaturaId] ON [Inscripcion] ([AsignaturaId]);
GO
CREATE INDEX [IX_Nota_AsignaturaId] ON [Nota] ([AsignaturaId]);
GO
CREATE INDEX [IX_Nota_EstudianteId] ON [Nota] ([EstudianteId]);
GO
CREATE INDEX [IX_Nota_ProfesorId] ON [Nota] ([ProfesorId]);
GO
CREATE INDEX [IX_Asistencia_AsignaturaId] ON [Asistencia] ([AsignaturaId]);
GO
CREATE INDEX [IX_Asistencia_EstudianteId] ON [Asistencia] ([EstudianteId]);
GO
CREATE INDEX [IX_Asistencia_ProfesorId] ON [Asistencia] ([ProfesorId]);
GO

-- ==========================================
-- 5. DATOS INICIALES
-- ==========================================

-- Roles del sistema
INSERT INTO [Rol] ([NombreRol]) VALUES ('Administrador');
INSERT INTO [Rol] ([NombreRol]) VALUES ('Estudiante');
INSERT INTO [Rol] ([NombreRol]) VALUES ('Profesor');
INSERT INTO [Rol] ([NombreRol]) VALUES ('Seguridad');
GO

-- Datos de prueba: Registro Institucional (Nómina)
-- Estos son datos de ejemplo. Reemplaza con los datos reales de tu grupo.
INSERT INTO [RegistroInstitucional] ([Cedula], [Nombres], [Apellidos], [CarreraDepartamento], [RolEsperado], [CorreoInstitucional])
VALUES 
    ('V-20000001', 'Juan Carlos', 'Pérez González', 'Informática', 'Estudiante', 'jperez@uptm.edu.ve'),
    ('V-20000002', 'María Elena', 'López Rodríguez', 'Informática', 'Estudiante', 'mlopez@uptm.edu.ve'),
    ('V-20000003', 'Carlos Alberto', 'Martínez Silva', 'Informática', 'Estudiante', 'cmartinez@uptm.edu.ve'),
    ('V-15000001', 'Ana María', 'García Fernández', 'Informática', 'Profesor', 'agarcia@uptm.edu.ve'),
    ('V-15000002', 'Pedro José', 'Ramírez Torres', 'Informática', 'Profesor', 'pramirez@uptm.edu.ve');
GO

-- Usuario administrador por defecto
INSERT INTO [Usuario] ([NombreUsuario], [ContrasenaHash], [Cedula], [RolId], [EstadoCuenta], [UltimoAcceso])
VALUES ('admin', 'admin123', NULL, 1, 1, GETDATE());
GO

-- ==========================================
-- 6. REGISTRAR MIGRACIONES EN EF CORE
-- ==========================================
-- Esto le dice a EF Core que las migraciones ya fueron aplicadas
INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20251227173236_AddControlAccesoAndMapping', N'9.0.10');

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260221212016_AddCedulaToUsuario', N'9.0.10');
GO

-- ============================================================
-- FIN DEL SCRIPT
-- Tablas creadas: 17
-- Rol, Carrera, Semestre, Periodo, Anuncio, 
-- RegistroInstitucional, ControlAcceso, Estudiante, Profesor,
-- Usuario, Asignatura, Horarios, Mensaje, Constancia,
-- Inscripcion, Nota, Asistencia
-- ============================================================
