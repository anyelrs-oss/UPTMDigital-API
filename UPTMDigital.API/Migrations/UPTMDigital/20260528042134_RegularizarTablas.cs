using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace UPTMDigital.API.Migrations.UPTMDigital
{
    /// <inheritdoc />
    public partial class RegularizarTablas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RegistroInstitucionalId",
                table: "Usuario",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Coordinador",
                columns: table => new
                {
                    IdCoordinador = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UsuarioId = table.Column<int>(type: "integer", nullable: false),
                    CarreraId = table.Column<int>(type: "integer", nullable: true),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Coordinador", x => x.IdCoordinador);
                    table.ForeignKey(
                        name: "FK_Coordinador_Carrera_CarreraId",
                        column: x => x.CarreraId,
                        principalTable: "Carrera",
                        principalColumn: "IdCarrera");
                    table.ForeignKey(
                        name: "FK_Coordinador_Usuario_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "Usuario",
                        principalColumn: "IdUsuario",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Usuario_RegistroInstitucionalId",
                table: "Usuario",
                column: "RegistroInstitucionalId");

            migrationBuilder.CreateIndex(
                name: "IX_PinAsistencia_CoordinadorId",
                table: "PinAsistencia",
                column: "CoordinadorId");

            migrationBuilder.CreateIndex(
                name: "IX_Coordinador_CarreraId",
                table: "Coordinador",
                column: "CarreraId");

            migrationBuilder.CreateIndex(
                name: "IX_Coordinador_UsuarioId",
                table: "Coordinador",
                column: "UsuarioId");

            migrationBuilder.AddForeignKey(
                name: "FK_PinAsistencia_Usuario_CoordinadorId",
                table: "PinAsistencia",
                column: "CoordinadorId",
                principalTable: "Usuario",
                principalColumn: "IdUsuario",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Usuario_RegistroInstitucional_RegistroInstitucionalId",
                table: "Usuario",
                column: "RegistroInstitucionalId",
                principalTable: "RegistroInstitucional",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PinAsistencia_Usuario_CoordinadorId",
                table: "PinAsistencia");

            migrationBuilder.DropForeignKey(
                name: "FK_Usuario_RegistroInstitucional_RegistroInstitucionalId",
                table: "Usuario");

            migrationBuilder.DropTable(
                name: "Coordinador");

            migrationBuilder.DropIndex(
                name: "IX_Usuario_RegistroInstitucionalId",
                table: "Usuario");

            migrationBuilder.DropIndex(
                name: "IX_PinAsistencia_CoordinadorId",
                table: "PinAsistencia");

            migrationBuilder.DropColumn(
                name: "RegistroInstitucionalId",
                table: "Usuario");
        }
    }
}
