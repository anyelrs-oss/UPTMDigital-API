using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Evaluaciones definidas por sección (parciales, trabajos, etc.) con su porcentaje.
    /// Tabla: evaluaciones | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("evaluaciones")]
    public class DareeEvaluacion
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("seccion_id")]
        public string? SeccionId { get; set; }

        [Column("nombre")]
        public string? Nombre { get; set; }

        [Column("porcentaje")]
        public decimal? Porcentaje { get; set; }

        [Column("fecha_evaluacion")]
        public DateTime? FechaEvaluacion { get; set; }
    }
}
