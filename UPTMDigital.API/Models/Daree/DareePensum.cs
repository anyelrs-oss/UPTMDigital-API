using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Malla curricular: Unidades Curriculares por PNF, trayecto y trimestre.
    /// Tabla: pensum | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("pensum")]
    public class DareePensum
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("pnf_id")]
        public int PnfId { get; set; }

        [Column("trayecto")]
        public string Trayecto { get; set; } = null!;

        [Column("trimestre")]
        public string Trimestre { get; set; } = null!;

        [Column("codigo_uc")]
        public string CodigoUc { get; set; } = null!;

        [Column("nombre_uc")]
        public string NombreUc { get; set; } = null!;

        [Column("unidades_credito")]
        public int UnidadesCredito { get; set; }

        [Column("tipo_uc")]
        public string TipoUc { get; set; } = "REGULAR";

        [Column("horas_academicas")]
        public int HorasAcademicas { get; set; }

        [Column("semanas")]
        public int Semanas { get; set; } = 12;

        [Column("creditos")]
        public int? Creditos { get; set; }

        [Column("nota_minima")]
        public int NotaMinima { get; set; } = 12;

        [Column("asistencia_minima")]
        public decimal AsistenciaMinima { get; set; } = 75.00m;

        [Column("permite_per")]
        public bool PermitePer { get; set; } = true;

        [Column("tipo")]
        public string? Tipo { get; set; } = "REGULAR";

        [Column("activo")]
        public bool? Activo { get; set; } = true;
    }
}
