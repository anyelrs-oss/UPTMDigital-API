using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace UPTMDigital.API.Migrations.UPTMDigital
{
    /// <inheritdoc />
    public partial class NotificacionesTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Notificacion",
                columns: table => new
                {
                    IdNotificacion = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    DestinatarioLogin = table.Column<string>(type: "text", nullable: false),
                    Titulo = table.Column<string>(type: "text", nullable: false),
                    Cuerpo = table.Column<string>(type: "text", nullable: false),
                    Tipo = table.Column<string>(type: "text", nullable: false),
                    Leida = table.Column<bool>(type: "boolean", nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notificacion", x => x.IdNotificacion);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Horarios_AsignaturaId",
                table: "Horarios",
                column: "AsignaturaId");

            migrationBuilder.AddForeignKey(
                name: "FK_Horarios_Asignatura_AsignaturaId",
                table: "Horarios",
                column: "AsignaturaId",
                principalTable: "Asignatura",
                principalColumn: "IdAsignatura",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Horarios_Asignatura_AsignaturaId",
                table: "Horarios");

            migrationBuilder.DropTable(
                name: "Notificacion");

            migrationBuilder.DropIndex(
                name: "IX_Horarios_AsignaturaId",
                table: "Horarios");
        }
    }
}
