using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("RegistroInstitucional")]
    public class RegistroInstitucional
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string Cedula { get; set; } = null!;
        
        public string Nombres { get; set; } = null!;
        public string Apellidos { get; set; } = null!;
        public string CarreraDepartamento { get; set; } = null!; // "Informatica" or "Sistemas"
        public string RolEsperado { get; set; } = null!; // "Estudiante" or "Profesor"
        public string CorreoInstitucional { get; set; } = null!;
    }
}
