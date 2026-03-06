using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Inscripcion")]
    public class Inscripcion
    {
        [Key]
        public int IdInscripcion { get; set; }
        public int EstudianteId { get; set; }
        public int AsignaturaId { get; set; }
        public string Periodo { get; set; } = null!;
        public DateTime? FechaInscripcion { get; set; }
        public string? Estado { get; set; }

        public Estudiante Estudiante { get; set; } = null!;
        public Asignatura Asignatura { get; set; } = null!;
    }
}