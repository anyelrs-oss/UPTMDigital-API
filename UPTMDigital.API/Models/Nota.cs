using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Nota")]
    public class Nota
    {
        [Key]
        public int IdNota { get; set; }
        public int AsignaturaId { get; set; }
        public int EstudianteId { get; set; }
        public decimal? Calificacion { get; set; }
        public DateTime? Fecha { get; set; }
        public int? ProfesorId { get; set; }
        public string? CodigoQR { get; set; }

        public Asignatura Asignatura { get; set; } = null!;
        public Estudiante Estudiante { get; set; } = null!;
        public Profesor? Profesor { get; set; }
    }
}