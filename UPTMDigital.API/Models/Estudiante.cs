using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Estudiante")]
    public class Estudiante
    {
        [Key]
        public int IdEstudiante { get; set; }
        public string Cedula { get; set; } = null!;
        public string Nombres { get; set; } = null!;
        public string Apellidos { get; set; } = null!;
        public string? CorreoInstitucional { get; set; }
        public string? CodAlumno { get; set; }
        public string? Telefono { get; set; }
        public string? Direccion { get; set; }

        // --- FK Normalizadas ---
        public int? UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        public int? CarreraId { get; set; }
        [ForeignKey("CarreraId")]
        public Carrera? Carrera { get; set; }

        // Campo calculado/legacy para compatibilidad
        [NotMapped]
        public string CarreraNombre => Carrera?.Nombre ?? "";

        public DateTime? FechaRegistro { get; set; }

        /// <summary>Estado del arancel: "Solvente" o "Pendiente". Controla acceso al carnet y constancias.</summary>
        public string EstadoArancel { get; set; } = "Pendiente";

        public bool Activo { get; set; } = true;
    }
}