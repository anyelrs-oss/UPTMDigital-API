CREATE DATABASE IF NOT EXISTS UPTMDigitalDB;
USE UPTMDigitalDB;


BEGIN
    CREATE TABLE `__EFMigrationsHistory` (
        `MigrationId` VARCHAR(150) NOT NULL,
        `ProductVersion` VARCHAR(32) NOT NULL,
        CONSTRAINT `PK___EFMigrationsHistory` PRIMARY KEY (`MigrationId`)
    );
END;
;


CREATE TABLE `Anuncio` (
    `IdAnuncio` int NOT NULL AUTO_INCREMENT,
    `Titulo` LONGTEXT NOT NULL,
    `Contenido` LONGTEXT NOT NULL,
    `FechaPublicacion` DATETIME NOT NULL,
    `Autor` LONGTEXT NULL,
    CONSTRAINT `PK_Anuncio` PRIMARY KEY (`IdAnuncio`)
);

CREATE TABLE `Carrera` (
    `IdCarrera` int NOT NULL AUTO_INCREMENT,
    `Nombre` LONGTEXT NOT NULL,
    CONSTRAINT `PK_Carrera` PRIMARY KEY (`IdCarrera`)
);

CREATE TABLE `ControlAcceso` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `Cedula` VARCHAR(20) NOT NULL,
    `PersonalSeguridadId` int NULL,
    `FechaHora` DATETIME NOT NULL,
    `Tipo` VARCHAR(10) NOT NULL,
    `Ubicacion` VARCHAR(50) NULL,
    CONSTRAINT `PK_ControlAcceso` PRIMARY KEY (`Id`)
);

CREATE TABLE `Estudiante` (
    `IdEstudiante` int NOT NULL AUTO_INCREMENT,
    `Cedula` LONGTEXT NOT NULL,
    `Nombres` LONGTEXT NOT NULL,
    `Apellidos` LONGTEXT NOT NULL,
    `CorreoInstitucional` LONGTEXT NULL,
    `CodAlumno` LONGTEXT NULL,
    `CodCarrera` LONGTEXT NULL,
    `Carrera` LONGTEXT NULL,
    `Direccion` LONGTEXT NULL,
    `Telefono` LONGTEXT NULL,
    `FechaRegistro` DATETIME NULL,
    `UsuarioLogin` LONGTEXT NULL,
    CONSTRAINT `PK_Estudiante` PRIMARY KEY (`IdEstudiante`)
);

CREATE TABLE `Horarios` (
    `IdHorario` int NOT NULL AUTO_INCREMENT,
    `AsignaturaId` int NOT NULL,
    `Dia` LONGTEXT NOT NULL,
    `HoraInicio` LONGTEXT NOT NULL,
    `HoraFin` LONGTEXT NOT NULL,
    `Aula` LONGTEXT NOT NULL,
    CONSTRAINT `PK_Horarios` PRIMARY KEY (`IdHorario`)
);

CREATE TABLE `Mensaje` (
    `IdMensaje` int NOT NULL AUTO_INCREMENT,
    `AsignaturaId` int NOT NULL,
    `Contenido` LONGTEXT NOT NULL,
    `FechaEnvio` DATETIME NOT NULL,
    `EmisorNombre` LONGTEXT NOT NULL,
    CONSTRAINT `PK_Mensaje` PRIMARY KEY (`IdMensaje`)
);

CREATE TABLE `Periodo` (
    `IdPeriodo` int NOT NULL AUTO_INCREMENT,
    `Nombre` LONGTEXT NOT NULL,
    `Activo` TINYINT(1) NOT NULL,
    CONSTRAINT `PK_Periodo` PRIMARY KEY (`IdPeriodo`)
);

CREATE TABLE `Profesor` (
    `IdProfesor` int NOT NULL AUTO_INCREMENT,
    `Cedula` LONGTEXT NOT NULL,
    `Nombres` LONGTEXT NOT NULL,
    `Apellidos` LONGTEXT NOT NULL,
    `CorreoInstitucional` LONGTEXT NULL,
    `CodProfesor` LONGTEXT NULL,
    `Departamento` LONGTEXT NULL,
    `Telefono` LONGTEXT NULL,
    `UsuarioLogin` LONGTEXT NULL,
    CONSTRAINT `PK_Profesor` PRIMARY KEY (`IdProfesor`)
);

CREATE TABLE `RegistroInstitucional` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `Cedula` LONGTEXT NOT NULL,
    `Nombres` LONGTEXT NOT NULL,
    `Apellidos` LONGTEXT NOT NULL,
    `CarreraDepartamento` LONGTEXT NOT NULL,
    `RolEsperado` LONGTEXT NOT NULL,
    `CorreoInstitucional` LONGTEXT NOT NULL,
    CONSTRAINT `PK_RegistroInstitucional` PRIMARY KEY (`Id`)
);

CREATE TABLE `Rol` (
    `IdRol` int NOT NULL AUTO_INCREMENT,
    `NombreRol` LONGTEXT NOT NULL,
    CONSTRAINT `PK_Rol` PRIMARY KEY (`IdRol`)
);

CREATE TABLE `Semestre` (
    `IdSemestre` int NOT NULL AUTO_INCREMENT,
    `Nombre` LONGTEXT NOT NULL,
    CONSTRAINT `PK_Semestre` PRIMARY KEY (`IdSemestre`)
);

CREATE TABLE `Constancia` (
    `IdConstancia` int NOT NULL AUTO_INCREMENT,
    `EstudianteId` int NOT NULL,
    `TipoConstancia` LONGTEXT NOT NULL,
    `Estado` LONGTEXT NULL,
    `FechaSolicitud` DATETIME NULL,
    `CodigoQR` LONGTEXT NULL,
    `ArchivoUrl` LONGTEXT NULL,
    CONSTRAINT `PK_Constancia` PRIMARY KEY (`IdConstancia`),
    CONSTRAINT `FK_Constancia_Estudiante_EstudianteId` FOREIGN KEY (`EstudianteId`) REFERENCES `Estudiante` (`IdEstudiante`) ON DELETE CASCADE
);

CREATE TABLE `Asignatura` (
    `IdAsignatura` int NOT NULL AUTO_INCREMENT,
    `Codi;` LONGTEXT NOT NULL,
    `Nombre` LONGTEXT NOT NULL,
    `Creditos` int NOT NULL,
    `Semestre` int NULL,
    `Departamento` LONGTEXT NULL,
    `ProfesorId` int NULL,
    CONSTRAINT `PK_Asignatura` PRIMARY KEY (`IdAsignatura`),
    CONSTRAINT `FK_Asignatura_Profesor_ProfesorId` FOREIGN KEY (`ProfesorId`) REFERENCES `Profesor` (`IdProfesor`)
);

CREATE TABLE `Usuario` (
    `IdUsuario` int NOT NULL AUTO_INCREMENT,
    `NombreUsuario` LONGTEXT NOT NULL,
    `ContrasenaHash` LONGTEXT NOT NULL,
    `RolId` int NOT NULL,
    `EstadoCuenta` TINYINT(1) NOT NULL,
    `UltimoAcceso` DATETIME NULL,
    CONSTRAINT `PK_Usuario` PRIMARY KEY (`IdUsuario`),
    CONSTRAINT `FK_Usuario_Rol_RolId` FOREIGN KEY (`RolId`) REFERENCES `Rol` (`IdRol`) ON DELETE CASCADE
);

CREATE TABLE `Asistencia` (
    `IdAsistencia` int NOT NULL AUTO_INCREMENT,
    `AsignaturaId` int NOT NULL,
    `EstudianteId` int NOT NULL,
    `Fecha` DATETIME NOT NULL,
    `Estado` LONGTEXT NOT NULL,
    `CodigoQR` LONGTEXT NULL,
    `ProfesorId` int NULL,
    CONSTRAINT `PK_Asistencia` PRIMARY KEY (`IdAsistencia`),
    CONSTRAINT `FK_Asistencia_Asignatura_AsignaturaId` FOREIGN KEY (`AsignaturaId`) REFERENCES `Asignatura` (`IdAsignatura`) ON DELETE CASCADE,
    CONSTRAINT `FK_Asistencia_Estudiante_EstudianteId` FOREIGN KEY (`EstudianteId`) REFERENCES `Estudiante` (`IdEstudiante`) ON DELETE CASCADE,
    CONSTRAINT `FK_Asistencia_Profesor_ProfesorId` FOREIGN KEY (`ProfesorId`) REFERENCES `Profesor` (`IdProfesor`)
);

CREATE TABLE `Inscripcion` (
    `IdInscripcion` int NOT NULL AUTO_INCREMENT,
    `EstudianteId` int NOT NULL,
    `AsignaturaId` int NOT NULL,
    `Periodo` LONGTEXT NOT NULL,
    `FechaInscripcion` DATETIME NULL,
    `Estado` LONGTEXT NULL,
    CONSTRAINT `PK_Inscripcion` PRIMARY KEY (`IdInscripcion`),
    CONSTRAINT `FK_Inscripcion_Asignatura_AsignaturaId` FOREIGN KEY (`AsignaturaId`) REFERENCES `Asignatura` (`IdAsignatura`) ON DELETE CASCADE,
    CONSTRAINT `FK_Inscripcion_Estudiante_EstudianteId` FOREIGN KEY (`EstudianteId`) REFERENCES `Estudiante` (`IdEstudiante`) ON DELETE CASCADE
);

CREATE TABLE `Nota` (
    `IdNota` int NOT NULL AUTO_INCREMENT,
    `AsignaturaId` int NOT NULL,
    `EstudianteId` int NOT NULL,
    `Calificacion` DECIMAL(18,2) NULL,
    `Fecha` DATETIME NULL,
    `ProfesorId` int NULL,
    `CodigoQR` LONGTEXT NULL,
    CONSTRAINT `PK_Nota` PRIMARY KEY (`IdNota`),
    CONSTRAINT `FK_Nota_Asignatura_AsignaturaId` FOREIGN KEY (`AsignaturaId`) REFERENCES `Asignatura` (`IdAsignatura`) ON DELETE CASCADE,
    CONSTRAINT `FK_Nota_Estudiante_EstudianteId` FOREIGN KEY (`EstudianteId`) REFERENCES `Estudiante` (`IdEstudiante`) ON DELETE CASCADE,
    CONSTRAINT `FK_Nota_Profesor_ProfesorId` FOREIGN KEY (`ProfesorId`) REFERENCES `Profesor` (`IdProfesor`)
);

CREATE INDEX `IX_Asignatura_ProfesorId` ON `Asignatura` (`ProfesorId`);

CREATE INDEX `IX_Asistencia_AsignaturaId` ON `Asistencia` (`AsignaturaId`);

CREATE INDEX `IX_Asistencia_EstudianteId` ON `Asistencia` (`EstudianteId`);

CREATE INDEX `IX_Asistencia_ProfesorId` ON `Asistencia` (`ProfesorId`);

CREATE INDEX `IX_Constancia_EstudianteId` ON `Constancia` (`EstudianteId`);

CREATE INDEX `IX_Inscripcion_AsignaturaId` ON `Inscripcion` (`AsignaturaId`);

CREATE INDEX `IX_Inscripcion_EstudianteId` ON `Inscripcion` (`EstudianteId`);

CREATE INDEX `IX_Nota_AsignaturaId` ON `Nota` (`AsignaturaId`);

CREATE INDEX `IX_Nota_EstudianteId` ON `Nota` (`EstudianteId`);

CREATE INDEX `IX_Nota_ProfesorId` ON `Nota` (`ProfesorId`);

CREATE INDEX `IX_Usuario_RolId` ON `Usuario` (`RolId`);

INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20260216173415_FullSchema', '9.0.10');


;



