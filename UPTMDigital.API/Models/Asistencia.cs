using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Asistencia")]
    public class Asistencia
    {
        [Key]
        public int IdAsistencia { get; set; }
        public int AsignaturaId { get; set; }
        public int EstudianteId { get; set; }
        public DateTime Fecha { get; set; }
        public string Estado { get; set; } = "Presente";
        public string? CodigoQR { get; set; }
        public int? ProfesorId { get; set; }

        public Asignatura Asignatura { get; set; } = null!;
        public Estudiante Estudiante { get; set; } = null!;
        public Profesor? Profesor { get; set; }
    }
}