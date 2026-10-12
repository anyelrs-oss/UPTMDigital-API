using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Bloques horarios por sección: día, hora inicio/fin, aula.
    /// Tabla: horarios | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("horarios")]
    public class DareeHorario
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("seccion_id")]
        public string SeccionId { get; set; } = null!;

        [Column("dia_semana")]
        public string? DiaSemana { get; set; }

        [Column("hora_inicio")]
        public TimeSpan? HoraInicio { get; set; }

        [Column("hora_fin")]
        public TimeSpan? HoraFin { get; set; }

        [Column("aula")]
        public string? Aula { get; set; }

        [Column("periodo")]
        public string? Periodo { get; set; }

        [Column("periodo_id")]
        public int? PeriodoId { get; set; }

        [Column("pnf_id")]
        public int? PnfId { get; set; }

        [Column("codigo_uc")]
        public string? CodigoUc { get; set; }

        [Column("nombre_uc")]
        public string? NombreUc { get; set; }

        [Column("docente_cedula")]
        public string? DocenteCedula { get; set; }

        [Column("aula_codigo")]
        public string? AulaCodigo { get; set; }

        [Column("edificio")]
        public string? Edificio { get; set; }

        [Column("estatus")]
        public string? Estatus { get; set; } = "ACTIVO";

        [Column("modalidad")]
        public string? Modalidad { get; set; } = "PRESENCIAL";

        [Column("bloque_num")]
        public short BloqueNum { get; set; } = 1;

        [Column("bloque_minutos")]
        public short BloqueMinutos { get; set; } = 45;

        [Column("pnf_color")]
        public string? PnfColor { get; set; }
    }
}
