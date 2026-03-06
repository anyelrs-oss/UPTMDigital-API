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
        public string? CodProfesor { get; set; } // Map to 'cod_profesor'
        public string? Departamento { get; set; }
        public string? Telefono { get; set; }
        public string? UsuarioLogin { get; set; }
    }
}