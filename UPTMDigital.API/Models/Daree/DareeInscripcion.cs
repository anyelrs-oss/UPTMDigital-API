using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Inscripción de un estudiante en una sección (materia del periodo).
    /// Tabla: inscripciones | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("inscripciones")]
    public class DareeInscripcion
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("estudiante_id")]
        public int EstudianteId { get; set; }

        [Column("seccion_id")]
        public string SeccionId { get; set; } = null!;

        [Column("periodo_id")]
        public int PeriodoId { get; set; }

        [Column("fecha_inscripcion")]
        public DateTime? FechaInscripcion { get; set; }

        /// <summary>
        /// INSCRITO | RETIRADO | APROBADO | REPROBADO
        /// </summary>
        [Column("estado")]
        public string? Estado { get; set; } = "INSCRITO";
    }
}
