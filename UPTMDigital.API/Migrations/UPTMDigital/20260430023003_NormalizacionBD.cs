using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UPTMDigital.API.Migrations.UPTMDigital
{
    /// <inheritdoc />
    public partial class NormalizacionBD : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "UsuarioLogin",
                table: "Profesor");

            migrationBuilder.DropColumn(
                name: "DestinatarioLogin",
                table: "Notificacion");

            migrationBuilder.DropColumn(
                name: "Periodo",
                table: "Inscripcion");

            migrationBuilder.DropColumn(
                name: "Carrera",
                table: "Estudiante");

            migrationBuilder.DropColumn(
                name: "CodCarrera",
                table: "Estudiante");

            migrationBuilder.DropColumn(
                name: "UsuarioLogin",
                table: "Estudiante");

            migrationBuilder.RenameColumn(
                name: "Semestre",
                table: "Asignatura",
                newName: "SemestreId");

            migrationBuilder.AddColumn<bool>(
                name: "Activo",
                table: "Usuario",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "Activo",
                table: "Profesor",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "UsuarioId",
                table: "Profesor",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UsuarioId",
                table: "Notificacion",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "UsuarioId",
                table: "Mensaje",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "PeriodoId",
                table: "Inscripcion",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "Activo",
                table: "Estudiante",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "CarreraId",
                table: "Estudiante",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UsuarioId",
                table: "Estudiante",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UsuarioId",
                table: "ControlAcceso",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "Activo",
                table: "Asignatura",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "CarreraId",
                table: "Asignatura",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "Activo",
                table: "Anuncio",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "UsuarioId",
                table: "Anuncio",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Profesor_UsuarioId",
                table: "Profesor",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Notificacion_UsuarioId",
                table: "Notificacion",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Mensaje_AsignaturaId",
                table: "Mensaje",
                column: "AsignaturaId");

            migrationBuilder.CreateIndex(
                name: "IX_Mensaje_UsuarioId",
                table: "Mensaje",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Inscripcion_PeriodoId",
                table: "Inscripcion",
                column: "PeriodoId");

            migrationBuilder.CreateIndex(
                name: "IX_Estudiante_CarreraId",
                table: "Estudiante",
                column: "CarreraId");

            migrationBuilder.CreateIndex(
                name: "IX_Estudiante_UsuarioId",
                table: "Estudiante",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_ControlAcceso_PersonalSeguridadId",
                table: "ControlAcceso",
                column: "PersonalSeguridadId");

            migrationBuilder.CreateIndex(
                name: "IX_ControlAcceso_UsuarioId",
                table: "ControlAcceso",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Asignatura_CarreraId",
                table: "Asignatura",
                column: "CarreraId");

            migrationBuilder.CreateIndex(
                name: "IX_Asignatura_SemestreId",
                table: "Asignatura",
                column: "SemestreId");

            migrationBuilder.CreateIndex(
                name: "IX_Anuncio_UsuarioId",
                table: "Anuncio",
                column: "UsuarioId");

            migrationBuilder.AddForeignKey(
                name: "FK_Anuncio_Usuario_UsuarioId",
                table: "Anuncio",
                column: "UsuarioId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Asignatura_Carrera_CarreraId",
                table: "Asignatura",
                column: "CarreraId",
                principalTable: "Carrera",
                principalColumn: "IdCarrera");

            migrationBuilder.AddForeignKey(
                name: "FK_Asignatura_Semestre_SemestreId",
                table: "Asignatura",
                column: "SemestreId",
                principalTable: "Semestre",
                principalColumn: "IdSemestre");

            migrationBuilder.AddForeignKey(
                name: "FK_ControlAcceso_Usuario_PersonalSeguridadId",
                table: "ControlAcceso",
                column: "PersonalSeguridadId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ControlAcceso_Usuario_UsuarioId",
                table: "ControlAcceso",
                column: "UsuarioId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Estudiante_Carrera_CarreraId",
                table: "Estudiante",
                column: "CarreraId",
                principalTable: "Carrera",
                principalColumn: "IdCarrera");

            migrationBuilder.AddForeignKey(
                name: "FK_Estudiante_Usuario_UsuarioId",
                table: "Estudiante",
                column: "UsuarioId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario");

            migrationBuilder.AddForeignKey(
                name: "FK_Inscripcion_Periodo_PeriodoId",
                table: "Inscripcion",
                column: "PeriodoId",
                principalTable: "Periodo",
                principalColumn: "IdPeriodo");

            migrationBuilder.AddForeignKey(
                name: "FK_Mensaje_Asignatura_AsignaturaId",
                table: "Mensaje",
                column: "AsignaturaId",
                principalTable: "Asignatura",
                principalColumn: "IdAsignatura",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Mensaje_Usuario_UsuarioId",
                table: "Mensaje",
                column: "UsuarioId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Notificacion_Usuario_UsuarioId",
                table: "Notificacion",
                column: "UsuarioId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Profesor_Usuario_UsuarioId",
                table: "Profesor",
                column: "UsuarioId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Anuncio_Usuario_UsuarioId",
                table: "Anuncio");

            migrationBuilder.DropForeignKey(
                name: "FK_Asignatura_Carrera_CarreraId",
                table: "Asignatura");

            migrationBuilder.DropForeignKey(
                name: "FK_Asignatura_Semestre_SemestreId",
                table: "Asignatura");

            migrationBuilder.DropForeignKey(
                name: "FK_ControlAcceso_Usuario_PersonalSeguridadId",
                table: "ControlAcceso");

            migrationBuilder.DropForeignKey(
                name: "FK_ControlAcceso_Usuario_UsuarioId",
                table: "ControlAcceso");

            migrationBuilder.DropForeignKey(
                name: "FK_Estudiante_Carrera_CarreraId",
                table: "Estudiante");

            migrationBuilder.DropForeignKey(
                name: "FK_Estudiante_Usuario_UsuarioId",
                table: "Estudiante");

            migrationBuilder.DropForeignKey(
                name: "FK_Inscripcion_Periodo_PeriodoId",
                table: "Inscripcion");

            migrationBuilder.DropForeignKey(
                name: "FK_Mensaje_Asignatura_AsignaturaId",
                table: "Mensaje");

            migrationBuilder.DropForeignKey(
                name: "FK_Mensaje_Usuario_UsuarioId",
                table: "Mensaje");

            migrationBuilder.DropForeignKey(
                name: "FK_Notificacion_Usuario_UsuarioId",
                table: "Notificacion");

            migrationBuilder.DropForeignKey(
                name: "FK_Profesor_Usuario_UsuarioId",
                table: "Profesor");

            migrationBuilder.DropIndex(
                name: "IX_Profesor_UsuarioId",
                table: "Profesor");

            migrationBuilder.DropIndex(
                name: "IX_Notificacion_UsuarioId",
                table: "Notificacion");

            migrationBuilder.DropIndex(
                name: "IX_Mensaje_AsignaturaId",
                table: "Mensaje");

            migrationBuilder.DropIndex(
                name: "IX_Mensaje_UsuarioId",
                table: "Mensaje");

            migrationBuilder.DropIndex(
                name: "IX_Inscripcion_PeriodoId",
                table: "Inscripcion");

            migrationBuilder.DropIndex(
                name: "IX_Estudiante_CarreraId",
                table: "Estudiante");

            migrationBuilder.DropIndex(
                name: "IX_Estudiante_UsuarioId",
                table: "Estudiante");

            migrationBuilder.DropIndex(
                name: "IX_ControlAcceso_PersonalSeguridadId",
                table: "ControlAcceso");

            migrationBuilder.DropIndex(
                name: "IX_ControlAcceso_UsuarioId",
                table: "ControlAcceso");

            migrationBuilder.DropIndex(
                name: "IX_Asignatura_CarreraId",
                table: "Asignatura");

            migrationBuilder.DropIndex(
                name: "IX_Asignatura_SemestreId",
                table: "Asignatura");

            migrationBuilder.DropIndex(
                name: "IX_Anuncio_UsuarioId",
                table: "Anuncio");

            migrationBuilder.DropColumn(
                name: "Activo",
                table: "Usuario");

            migrationBuilder.DropColumn(
                name: "Activo",
                table: "Profesor");

            migrationBuilder.DropColumn(
                name: "UsuarioId",
                table: "Profesor");

            migrationBuilder.DropColumn(
                name: "UsuarioId",
                table: "Notificacion");

            migrationBuilder.DropColumn(
                name: "UsuarioId",
                table: "Mensaje");

            migrationBuilder.DropColumn(
                name: "PeriodoId",
                table: "Inscripcion");

            migrationBuilder.DropColumn(
                name: "Activo",
                table: "Estudiante");

            migrationBuilder.DropColumn(
                name: "CarreraId",
                table: "Estudiante");

            migrationBuilder.DropColumn(
                name: "UsuarioId",
                table: "Estudiante");

            migrationBuilder.DropColumn(
                name: "UsuarioId",
                table: "ControlAcceso");

            migrationBuilder.DropColumn(
                name: "Activo",
                table: "Asignatura");

            migrationBuilder.DropColumn(
                name: "CarreraId",
                table: "Asignatura");

            migrationBuilder.DropColumn(
                name: "Activo",
                table: "Anuncio");

            migrationBuilder.DropColumn(
                name: "UsuarioId",
                table: "Anuncio");

            migrationBuilder.RenameColumn(
                name: "SemestreId",
                table: "Asignatura",
                newName: "Semestre");

            migrationBuilder.AddColumn<string>(
                name: "UsuarioLogin",
                table: "Profesor",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DestinatarioLogin",
                table: "Notificacion",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Periodo",
                table: "Inscripcion",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Carrera",
                table: "Estudiante",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CodCarrera",
                table: "Estudiante",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UsuarioLogin",
                table: "Estudiante",
                type: "text",
                nullable: true);
        }
    }
}
