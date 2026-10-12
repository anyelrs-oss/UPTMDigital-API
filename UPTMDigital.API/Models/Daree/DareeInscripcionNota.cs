using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Notas de un estudiante en una sección (UC inscrita).
    /// Contiene notas parciales (c1-c4), asistencia y definitiva.
    /// Tabla: inscripciones_notas | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("inscripciones_notas")]
    public class DareeInscripcionNota
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("estudiante_cedula")]
        public string EstudianteCedula { get; set; } = null!;

        [Column("seccion_id")]
        public string SeccionId { get; set; } = null!;

        [Column("c1")]
        public decimal? C1 { get; set; }

        [Column("c2")]
        public decimal? C2 { get; set; }

        [Column("c3")]
        public decimal? C3 { get; set; }

        [Column("c4")]
        public decimal? C4 { get; set; }

        [Column("asistencia")]
        public decimal? Asistencia { get; set; } = 100.00m;

        [Column("definitiva")]
        public int? Definitiva { get; set; }

        [Column("estatus_materia")]
        public string? EstatusMateria { get; set; } = "CURSANDO";

        [Column("asistencia_presencial")]
        public decimal AsistenciaPresencial { get; set; }

        [Column("asistencia_virtual")]
        public decimal AsistenciaVirtual { get; set; }

        [Column("es_per")]
        public bool EsPer { get; set; }

        [Column("per_id")]
        public long? PerId { get; set; }

        [Column("fecha_actualizacion")]
        public DateTime? FechaActualizacion { get; set; }
    }
}
