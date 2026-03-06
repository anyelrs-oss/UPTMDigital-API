using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("ControlAcceso")]
    public class ControlAcceso
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(20)]
        public string Cedula { get; set; } = null!; // Link to Estudiante/Profesor by Cedula

        public int? PersonalSeguridadId { get; set; } // ID of the Security User who scanned it

        public DateTime FechaHora { get; set; } = DateTime.Now;

        [Required]
        [MaxLength(10)]
        public string Tipo { get; set; } = null!; // "Entrada" or "Salida"

        [MaxLength(50)]
        public string? Ubicacion { get; set; }
    }
}
