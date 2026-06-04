using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("EvaluacionConfig")]
    public class EvaluacionConfig
    {
        [Key]
        public int IdEvaluacion { get; set; }

        public int AsignaturaId { get; set; }
        [ForeignKey("AsignaturaId")]
        public Asignatura? Asignatura { get; set; }

        public string Nombre { get; set; } = null!; // Ej: "Examen 1", "Proyecto Final"

        public decimal Ponderacion { get; set; } // Porcentaje (0-100)

        public DateTime FechaEvaluacion { get; set; }

        public bool Activo { get; set; } = true;
    }
}
