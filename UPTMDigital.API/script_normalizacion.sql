START TRANSACTION;
ALTER TABLE "Profesor" DROP COLUMN "UsuarioLogin";

ALTER TABLE "Notificacion" DROP COLUMN "DestinatarioLogin";

ALTER TABLE "Inscripcion" DROP COLUMN "Periodo";

ALTER TABLE "Estudiante" DROP COLUMN "Carrera";

ALTER TABLE "Estudiante" DROP COLUMN "CodCarrera";

ALTER TABLE "Estudiante" DROP COLUMN "UsuarioLogin";

ALTER TABLE "Asignatura" RENAME COLUMN "Semestre" TO "SemestreId";

ALTER TABLE "Usuario" ADD "Activo" boolean NOT NULL DEFAULT FALSE;

ALTER TABLE "Profesor" ADD "Activo" boolean NOT NULL DEFAULT FALSE;

ALTER TABLE "Profesor" ADD "UsuarioId" integer;

ALTER TABLE "Notificacion" ADD "UsuarioId" integer NOT NULL DEFAULT 0;

ALTER TABLE "Mensaje" ADD "UsuarioId" integer NOT NULL DEFAULT 0;

ALTER TABLE "Inscripcion" ADD "PeriodoId" integer;

ALTER TABLE "Estudiante" ADD "Activo" boolean NOT NULL DEFAULT FALSE;

ALTER TABLE "Estudiante" ADD "CarreraId" integer;

ALTER TABLE "Estudiante" ADD "UsuarioId" integer;

ALTER TABLE "ControlAcceso" ADD "UsuarioId" integer;

ALTER TABLE "Asignatura" ADD "Activo" boolean NOT NULL DEFAULT FALSE;

ALTER TABLE "Asignatura" ADD "CarreraId" integer;

ALTER TABLE "Anuncio" ADD "Activo" boolean NOT NULL DEFAULT FALSE;

ALTER TABLE "Anuncio" ADD "UsuarioId" integer;

CREATE INDEX "IX_Profesor_UsuarioId" ON "Profesor" ("UsuarioId");

CREATE INDEX "IX_Notificacion_UsuarioId" ON "Notificacion" ("UsuarioId");

CREATE INDEX "IX_Mensaje_AsignaturaId" ON "Mensaje" ("AsignaturaId");

CREATE INDEX "IX_Mensaje_UsuarioId" ON "Mensaje" ("UsuarioId");

CREATE INDEX "IX_Inscripcion_PeriodoId" ON "Inscripcion" ("PeriodoId");

CREATE INDEX "IX_Estudiante_CarreraId" ON "Estudiante" ("CarreraId");

CREATE INDEX "IX_Estudiante_UsuarioId" ON "Estudiante" ("UsuarioId");

CREATE INDEX "IX_ControlAcceso_PersonalSeguridadId" ON "ControlAcceso" ("PersonalSeguridadId");

CREATE INDEX "IX_ControlAcceso_UsuarioId" ON "ControlAcceso" ("UsuarioId");

CREATE INDEX "IX_Asignatura_CarreraId" ON "Asignatura" ("CarreraId");

CREATE INDEX "IX_Asignatura_SemestreId" ON "Asignatura" ("SemestreId");

CREATE INDEX "IX_Anuncio_UsuarioId" ON "Anuncio" ("UsuarioId");

ALTER TABLE "Anuncio" ADD CONSTRAINT "FK_Anuncio_Usuario_UsuarioId" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario" ("IdUsuario") ON DELETE RESTRICT;

ALTER TABLE "Asignatura" ADD CONSTRAINT "FK_Asignatura_Carrera_CarreraId" FOREIGN KEY ("CarreraId") REFERENCES "Carrera" ("IdCarrera");

ALTER TABLE "Asignatura" ADD CONSTRAINT "FK_Asignatura_Semestre_SemestreId" FOREIGN KEY ("SemestreId") REFERENCES "Semestre" ("IdSemestre");

ALTER TABLE "ControlAcceso" ADD CONSTRAINT "FK_ControlAcceso_Usuario_PersonalSeguridadId" FOREIGN KEY ("PersonalSeguridadId") REFERENCES "Usuario" ("IdUsuario") ON DELETE RESTRICT;

ALTER TABLE "ControlAcceso" ADD CONSTRAINT "FK_ControlAcceso_Usuario_UsuarioId" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario" ("IdUsuario") ON DELETE RESTRICT;

ALTER TABLE "Estudiante" ADD CONSTRAINT "FK_Estudiante_Carrera_CarreraId" FOREIGN KEY ("CarreraId") REFERENCES "Carrera" ("IdCarrera");

ALTER TABLE "Estudiante" ADD CONSTRAINT "FK_Estudiante_Usuario_UsuarioId" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario" ("IdUsuario");

ALTER TABLE "Inscripcion" ADD CONSTRAINT "FK_Inscripcion_Periodo_PeriodoId" FOREIGN KEY ("PeriodoId") REFERENCES "Periodo" ("IdPeriodo");

ALTER TABLE "Mensaje" ADD CONSTRAINT "FK_Mensaje_Asignatura_AsignaturaId" FOREIGN KEY ("AsignaturaId") REFERENCES "Asignatura" ("IdAsignatura") ON DELETE RESTRICT;

ALTER TABLE "Mensaje" ADD CONSTRAINT "FK_Mensaje_Usuario_UsuarioId" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario" ("IdUsuario") ON DELETE RESTRICT;

ALTER TABLE "Notificacion" ADD CONSTRAINT "FK_Notificacion_Usuario_UsuarioId" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario" ("IdUsuario") ON DELETE RESTRICT;

ALTER TABLE "Profesor" ADD CONSTRAINT "FK_Profesor_Usuario_UsuarioId" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario" ("IdUsuario");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260430023003_NormalizacionBD', '9.0.10');

COMMIT;

