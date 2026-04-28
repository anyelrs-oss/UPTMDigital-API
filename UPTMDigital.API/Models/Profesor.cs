using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Profesor")]
    public class Profesor
    {
        [Key]
        public int IdProfesor { get; set; }
        public string Cedula { get; set; } = null!;
        public string Nombres { get; set; } = null!;
        public string Apellidos { get; set; } = null!;
        public string? CorreoInstitucional { get; set; }
        public string? CodProfesor { get; set; }
        public string? Departamento { get; set; }
        public string? Telefono { get; set; }

        // --- FK Normalizada ---
        public int? UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        public bool Activo { get; set; } = true;
    }
}