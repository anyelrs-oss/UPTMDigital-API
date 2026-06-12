using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UPTMDigital.API.Migrations.UPTMDigital
{
    /// <inheritdoc />
    public partial class FixCoordinadorTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Cedula",
                table: "Usuario",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CarreraId",
                table: "PinAsistencia",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "EvaluacionId",
                table: "Nota",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CarreraId",
                table: "Mensaje",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Apellidos",
                table: "Coordinador",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Nombres",
                table: "Coordinador",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Trimestre",
                table: "Anuncio",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "GlobalSetting",
                columns: table => new
                {
                    Clave = table.Column<string>(type: "text", nullable: false),
                    Valor = table.Column<string>(type: "text", nullable: false),
                    UltimaActualizacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GlobalSetting", x => x.Clave);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Usuario_Cedula",
                table: "Usuario",
                column: "Cedula",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PinAsistencia_CarreraId",
                table: "PinAsistencia",
                column: "CarreraId");

            migrationBuilder.CreateIndex(
                name: "IX_Nota_EvaluacionId",
                table: "Nota",
                column: "EvaluacionId");

            migrationBuilder.CreateIndex(
                name: "IX_Mensaje_CarreraId",
                table: "Mensaje",
                column: "CarreraId");

            migrationBuilder.AddForeignKey(
                name: "FK_Mensaje_Carrera_CarreraId",
                table: "Mensaje",
                column: "CarreraId",
                principalTable: "Carrera",
                principalColumn: "IdCarrera");

            migrationBuilder.AddForeignKey(
                name: "FK_Nota_EvaluacionConfig_EvaluacionId",
                table: "Nota",
                column: "EvaluacionId",
                principalTable: "EvaluacionConfig",
                principalColumn: "IdEvaluacion");

            migrationBuilder.AddForeignKey(
                name: "FK_PinAsistencia_Carrera_CarreraId",
                table: "PinAsistencia",
                column: "CarreraId",
                principalTable: "Carrera",
                principalColumn: "IdCarrera");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Mensaje_Carrera_CarreraId",
                table: "Mensaje");

            migrationBuilder.DropForeignKey(
                name: "FK_Nota_EvaluacionConfig_EvaluacionId",
                table: "Nota");

            migrationBuilder.DropForeignKey(
                name: "FK_PinAsistencia_Carrera_CarreraId",
                table: "PinAsistencia");

            migrationBuilder.DropTable(
                name: "GlobalSetting");

            migrationBuilder.DropIndex(
                name: "IX_Usuario_Cedula",
                table: "Usuario");

            migrationBuilder.DropIndex(
                name: "IX_PinAsistencia_CarreraId",
                table: "PinAsistencia");

            migrationBuilder.DropIndex(
                name: "IX_Nota_EvaluacionId",
                table: "Nota");

            migrationBuilder.DropIndex(
                name: "IX_Mensaje_CarreraId",
                table: "Mensaje");

            migrationBuilder.DropColumn(
                name: "CarreraId",
                table: "PinAsistencia");

            migrationBuilder.DropColumn(
                name: "EvaluacionId",
                table: "Nota");

            migrationBuilder.DropColumn(
                name: "CarreraId",
                table: "Mensaje");

            migrationBuilder.DropColumn(
                name: "Apellidos",
                table: "Coordinador");

            migrationBuilder.DropColumn(
                name: "Nombres",
                table: "Coordinador");

            migrationBuilder.DropColumn(
                name: "Trimestre",
                table: "Anuncio");

            migrationBuilder.AlterColumn<string>(
                name: "Cedula",
                table: "Usuario",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");
        }
    }
}
