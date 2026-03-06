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
        public string? CodAlumno { get; set; } // Map to 'cod_alumno'
        public string? CodCarrera { get; set; } // Map to 'cod_carrera'
        public string? Carrera { get; set; }
        public string? Direccion { get; set; }
        public string? Telefono { get; set; }

        public DateTime? FechaRegistro { get; set; }
        public string? UsuarioLogin { get; set; }
    }
}