using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    public class Horario
    {
        [Key]
        public int IdHorario { get; set; }

        public int AsignaturaId { get; set; }

        [Required]
        public string Dia { get; set; } = string.Empty; // e.g., "Lunes"

        [Required]
        public string HoraInicio { get; set; } = string.Empty; // e.g., "08:00"

        [Required]
        public string HoraFin { get; set; } = string.Empty; // e.g., "10:00"

        public string Aula { get; set; } = string.Empty;

        // Relation (optional if we want to include details)
        // [ForeignKey("AsignaturaId")]
        // public Asignatura? Asignatura { get; set; }
    }
}
