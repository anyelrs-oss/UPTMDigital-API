using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Inscripcion")]
    public class Inscripcion
    {
        [Key]
        public int IdInscripcion { get; set; }

        // --- FK Normalizadas ---
        public int EstudianteId { get; set; }
        [ForeignKey("EstudianteId")]
        public Estudiante Estudiante { get; set; } = null!;

        public int AsignaturaId { get; set; }
        [ForeignKey("AsignaturaId")]
        public Asignatura Asignatura { get; set; } = null!;

        public int? PeriodoId { get; set; }
        [ForeignKey("PeriodoId")]
        public Periodo? Periodo { get; set; }

        public DateTime? FechaInscripcion { get; set; }
        public string? Estado { get; set; }
        public bool Activo { get; set; } = true;
    }
}