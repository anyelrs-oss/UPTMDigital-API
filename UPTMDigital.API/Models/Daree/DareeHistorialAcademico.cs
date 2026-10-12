using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Historial académico: registro consolidado de todas las UCs cursadas con nota final.
    /// Tabla: historial_academico | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("historial_academico")]
    public class DareeHistorialAcademico
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("estudiante_id")]
        public int EstudianteId { get; set; }

        [Column("pnf_id")]
        public int PnfId { get; set; }

        [Column("codigo_uc")]
        public string? CodigoUc { get; set; }

        [Column("nombre_uc")]
        public string? NombreUc { get; set; }

        [Column("trayecto")]
        public string? Trayecto { get; set; }

        [Column("trimestre")]
        public string? Trimestre { get; set; }

        [Column("unidades_credito")]
        public int? UnidadesCredito { get; set; }

        [Column("nota_final")]
        public decimal? NotaFinal { get; set; }

        /// <summary>
        /// APROBADO | REPROBADO | EQUIVALENCIA | RETIRO
        /// </summary>
        [Column("condicion")]
        public string? Condicion { get; set; }

        [Column("periodo")]
        public string? Periodo { get; set; }

        [Column("fecha_cierre")]
        public DateTime? FechaCierre { get; set; }
    }
}
