using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Registro de asistencia por estudiante, sección y fecha.
    /// Tabla: asistencias | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("asistencias")]
    public class DareeAsistencia
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("estudiante_cedula")]
        public string EstudianteCedula { get; set; } = null!;

        [Column("seccion_id")]
        public string SeccionId { get; set; } = null!;

        [Column("fecha")]
        public DateTime Fecha { get; set; }

        /// <summary>
        /// PRESENTE | AUSENTE | JUSTIFICADO | TARDANZA
        /// </summary>
        [Column("estado")]
        public string Estado { get; set; } = "PRESENTE";

        [Column("observacion")]
        public string? Observacion { get; set; }

        [Column("registrado_por")]
        public long? RegistradoPor { get; set; }

        [Column("creado_en")]
        public DateTime? CreadoEn { get; set; }
    }
}
