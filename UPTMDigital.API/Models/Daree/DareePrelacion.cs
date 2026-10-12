using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Prerrequisitos entre unidades curriculares (cadena de prelaciones).
    /// Tabla: prelaciones | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("prelaciones")]
    public class DareePrelacion
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("pnf_id")]
        public int? PnfId { get; set; }

        [Column("uc_codigo")]
        public string? UcCodigo { get; set; }

        [Column("uc_nombre")]
        public string? UcNombre { get; set; }

        [Column("requiere_codigo")]
        public string? RequiereCodigo { get; set; }

        [Column("requiere_nombre")]
        public string? RequiereNombre { get; set; }

        [Column("tipo")]
        public string Tipo { get; set; } = "NORMAL";

        [Column("activo")]
        public bool Activo { get; set; }
    }
}
