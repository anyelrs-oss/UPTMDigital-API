using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace UPTMDigital.API.Migrations.UPTMDigital
{
    /// <inheritdoc />
    public partial class Fase2_Completa : Migration
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
                name: "ReceptorUsuarioId",
                table: "Mensaje",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Seccion",
                table: "Mensaje",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TipoChat",
                table: "Mensaje",
                type: "text",
                nullable: false,
                defaultValue: "");

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

            migrationBuilder.AddColumn<bool>(
                name: "EstadoArancel",
                table: "Estudiante",
                type: "boolean",
                nullable: false,
                defaultValue: false);

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
                name: "CarreraId",
                table: "Anuncio",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Prioridad",
                table: "Anuncio",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "RolId",
                table: "Anuncio",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UsuarioId",
                table: "Anuncio",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ArancelValidacion",
                columns: table => new
                {
                    IdValidacion = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CedulaEstudiante = table.Column<string>(type: "text", nullable: false),
                    NumeroFactura = table.Column<string>(type: "text", nullable: false),
                    FechaValidacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    SecretariaId = table.Column<int>(type: "integer", nullable: true),
                    MetodoPago = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ArancelValidacion", x => x.IdValidacion);
                    table.ForeignKey(
                        name: "FK_ArancelValidacion_Usuario_SecretariaId",
                        column: x => x.SecretariaId,
                        principalTable: "Usuario",
                        principalColumn: "IdUsuario");
                });

            migrationBuilder.CreateTable(
                name: "AuditLog",
                columns: table => new
                {
                    IdAudit = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UsuarioId = table.Column<int>(type: "integer", nullable: true),
                    Accion = table.Column<string>(type: "text", nullable: false),
                    Ruta = table.Column<string>(type: "text", nullable: false),
                    IP = table.Column<string>(type: "text", nullable: false),
                    Fecha = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Detalles = table.Column<string>(type: "text", nullable: true),
                    MotivoJustificado = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLog", x => x.IdAudit);
                    table.ForeignKey(
                        name: "FK_AuditLog_Usuario_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "Usuario",
                        principalColumn: "IdUsuario");
                });

            migrationBuilder.CreateTable(
                name: "Aula",
                columns: table => new
                {
                    IdAula = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Nombre = table.Column<string>(type: "text", nullable: false),
                    Edificio = table.Column<string>(type: "text", nullable: false),
                    Piso = table.Column<string>(type: "text", nullable: false),
                    Estado = table.Column<string>(type: "text", nullable: false),
                    HoraApertura = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ProfesorActualId = table.Column<int>(type: "integer", nullable: true),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Aula", x => x.IdAula);
                    table.ForeignKey(
                        name: "FK_Aula_Profesor_ProfesorActualId",
                        column: x => x.ProfesorActualId,
                        principalTable: "Profesor",
                        principalColumn: "IdProfesor");
                });

            migrationBuilder.CreateTable(
                name: "EvaluacionConfig",
                columns: table => new
                {
                    IdEvaluacion = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    AsignaturaId = table.Column<int>(type: "integer", nullable: false),
                    Nombre = table.Column<string>(type: "text", nullable: false),
                    Ponderacion = table.Column<decimal>(type: "numeric", nullable: false),
                    FechaEvaluacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EvaluacionConfig", x => x.IdEvaluacion);
                    table.ForeignKey(
                        name: "FK_EvaluacionConfig_Asignatura_AsignaturaId",
                        column: x => x.AsignaturaId,
                        principalTable: "Asignatura",
                        principalColumn: "IdAsignatura",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PinAsistencia",
                columns: table => new
                {
                    IdPin = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Pin = table.Column<string>(type: "text", nullable: false),
                    FechaExpiracion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CoordinadorId = table.Column<int>(type: "integer", nullable: true),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PinAsistencia", x => x.IdPin);
                });

            migrationBuilder.CreateTable(
                name: "SolicitudApertura",
                columns: table => new
                {
                    IdSolicitud = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    AulaId = table.Column<int>(type: "integer", nullable: false),
                    ProfesorId = table.Column<int>(type: "integer", nullable: false),
                    PersonalSeguridadId = table.Column<int>(type: "integer", nullable: true),
                    FechaSolicitud = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FechaAtencion = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    FechaCompletada = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Estado = table.Column<string>(type: "text", nullable: false),
                    Motivo = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SolicitudApertura", x => x.IdSolicitud);
                    table.ForeignKey(
                        name: "FK_SolicitudApertura_Aula_AulaId",
                        column: x => x.AulaId,
                        principalTable: "Aula",
                        principalColumn: "IdAula",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SolicitudApertura_Profesor_ProfesorId",
                        column: x => x.ProfesorId,
                        principalTable: "Profesor",
                        principalColumn: "IdProfesor",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SolicitudApertura_Usuario_PersonalSeguridadId",
                        column: x => x.PersonalSeguridadId,
                        principalTable: "Usuario",
                        principalColumn: "IdUsuario",
                        onDelete: ReferentialAction.Restrict);
                });

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
                name: "IX_Mensaje_ReceptorUsuarioId",
                table: "Mensaje",
                column: "ReceptorUsuarioId");

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
                name: "IX_Estudiante_Cedula",
                table: "Estudiante",
                column: "Cedula",
                unique: true);

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
                name: "IX_Anuncio_CarreraId",
                table: "Anuncio",
                column: "CarreraId");

            migrationBuilder.CreateIndex(
                name: "IX_Anuncio_RolId",
                table: "Anuncio",
                column: "RolId");

            migrationBuilder.CreateIndex(
                name: "IX_Anuncio_UsuarioId",
                table: "Anuncio",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_ArancelValidacion_SecretariaId",
                table: "ArancelValidacion",
                column: "SecretariaId");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLog_UsuarioId",
                table: "AuditLog",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Aula_ProfesorActualId",
                table: "Aula",
                column: "ProfesorActualId");

            migrationBuilder.CreateIndex(
                name: "IX_EvaluacionConfig_AsignaturaId",
                table: "EvaluacionConfig",
                column: "AsignaturaId");

            migrationBuilder.CreateIndex(
                name: "IX_SolicitudApertura_AulaId",
                table: "SolicitudApertura",
                column: "AulaId");

            migrationBuilder.CreateIndex(
                name: "IX_SolicitudApertura_PersonalSeguridadId",
                table: "SolicitudApertura",
                column: "PersonalSeguridadId");

            migrationBuilder.CreateIndex(
                name: "IX_SolicitudApertura_ProfesorId",
                table: "SolicitudApertura",
                column: "ProfesorId");

            migrationBuilder.AddForeignKey(
                name: "FK_Anuncio_Carrera_CarreraId",
                table: "Anuncio",
                column: "CarreraId",
                principalTable: "Carrera",
                principalColumn: "IdCarrera");

            migrationBuilder.AddForeignKey(
                name: "FK_Anuncio_Rol_RolId",
                table: "Anuncio",
                column: "RolId",
                principalTable: "Rol",
                principalColumn: "IdRol");

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
                name: "FK_Mensaje_Usuario_ReceptorUsuarioId",
                table: "Mensaje",
                column: "ReceptorUsuarioId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario");

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
                name: "FK_Anuncio_Carrera_CarreraId",
                table: "Anuncio");

            migrationBuilder.DropForeignKey(
                name: "FK_Anuncio_Rol_RolId",
                table: "Anuncio");

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
                name: "FK_Mensaje_Usuario_ReceptorUsuarioId",
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

            migrationBuilder.DropTable(
                name: "ArancelValidacion");

            migrationBuilder.DropTable(
                name: "AuditLog");

            migrationBuilder.DropTable(
                name: "EvaluacionConfig");

            migrationBuilder.DropTable(
                name: "PinAsistencia");

            migrationBuilder.DropTable(
                name: "SolicitudApertura");

            migrationBuilder.DropTable(
                name: "Aula");

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
                name: "IX_Mensaje_ReceptorUsuarioId",
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
                name: "IX_Estudiante_Cedula",
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
                name: "IX_Anuncio_CarreraId",
                table: "Anuncio");

            migrationBuilder.DropIndex(
                name: "IX_Anuncio_RolId",
                table: "Anuncio");

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
                name: "ReceptorUsuarioId",
                table: "Mensaje");

            migrationBuilder.DropColumn(
                name: "Seccion",
                table: "Mensaje");

            migrationBuilder.DropColumn(
                name: "TipoChat",
                table: "Mensaje");

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
                name: "EstadoArancel",
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
                name: "CarreraId",
                table: "Anuncio");

            migrationBuilder.DropColumn(
                name: "Prioridad",
                table: "Anuncio");

            migrationBuilder.DropColumn(
                name: "RolId",
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
