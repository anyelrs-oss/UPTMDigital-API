using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Asignación de docentes a secciones (carga académica docente).
    /// Tabla: carga_docente | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("carga_docente")]
    public class DareeCargaDocente
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("docente_cedula")]
        public string DocenteCedula { get; set; } = null!;

        [Column("seccion_id")]
        public string SeccionId { get; set; } = null!;

        [Column("rol_docente")]
        public string RolDocente { get; set; } = "TITULAR";

        [Column("horas_academicas")]
        public int HorasAcademicas { get; set; }

        [Column("estado")]
        public string Estado { get; set; } = "ASIGNADO";

        [Column("fecha_asignacion")]
        public DateTime FechaAsignacion { get; set; }

        [Column("asignado_por")]
        public string? AsignadoPor { get; set; }
    }
}
