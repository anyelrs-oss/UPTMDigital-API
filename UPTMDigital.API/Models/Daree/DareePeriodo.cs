using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Periodos académicos (ej: 2026-I). Solo uno activo a la vez.
    /// Tabla: periodos_academicos | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("periodos_academicos")]
    public class DareePeriodo
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("codigo")]
        public string? Codigo { get; set; }

        [Column("nombre")]
        public string? Nombre { get; set; }

        [Column("descripcion")]
        public string? Descripcion { get; set; }

        [Column("fecha_inicio")]
        public DateTime? FechaInicio { get; set; }

        [Column("fecha_fin")]
        public DateTime? FechaFin { get; set; }

        [Column("activo")]
        public bool Activo { get; set; }

        [Column("estatus")]
        public string Estatus { get; set; } = "ABIERTO";

        [Column("fase")]
        public string Fase { get; set; } = "PLANIFICACION";

        [Column("bloquea_inscripciones")]
        public bool BloqueaInscripciones { get; set; }

        [Column("bloquea_notas")]
        public bool BloqueaNotas { get; set; }
    }
}
