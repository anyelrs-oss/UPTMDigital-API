using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Secciones académicas (oferta del periodo): una sección = una UC + docente + horario.
    /// Tabla: secciones | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("secciones")]
    public class DareeSeccion
    {
        [Key]
        [Column("id")]
        public string Id { get; set; } = null!;

        [Column("periodo")]
        public string Periodo { get; set; } = null!;

        [Column("pnf_id")]
        public int PnfId { get; set; }

        [Column("trayecto")]
        public string Trayecto { get; set; } = null!;

        [Column("trimestre")]
        public string Trimestre { get; set; } = null!;

        [Column("codigo_uc")]
        public string CodigoUc { get; set; } = null!;

        [Column("letra_seccion")]
        public string LetraSeccion { get; set; } = null!;

        [Column("cupos_maximos")]
        public int CuposMaximos { get; set; } = 30;

        [Column("docente_cedula")]
        public string? DocenteCedula { get; set; }

        [Column("edificio")]
        public string? Edificio { get; set; }

        [Column("aula")]
        public string? Aula { get; set; }

        [Column("aula_codigo")]
        public string? AulaCodigo { get; set; }

        [Column("color_hex")]
        public string? ColorHex { get; set; }

        [Column("nombre_uc")]
        public string? NombreUc { get; set; }

        [Column("unidades_credito")]
        public int UnidadesCredito { get; set; }

        [Column("inscritos")]
        public int Inscritos { get; set; }

        [Column("estatus")]
        public string? Estatus { get; set; } = "ACTIVA";

        [Column("tipo")]
        public string? Tipo { get; set; } = "REGULAR";

        [Column("periodo_id")]
        public int? PeriodoId { get; set; }

        [Column("cupo_maximo")]
        public int CupoMaximo { get; set; } = 35;

        [Column("docente_nombre")]
        public string? DocenteNombre { get; set; }

        [Column("dia_semana")]
        public string? DiaSemana { get; set; }

        [Column("hora_inicio")]
        public TimeSpan? HoraInicio { get; set; }

        [Column("hora_fin")]
        public TimeSpan? HoraFin { get; set; }

        [Column("horario")]
        public string? Horario { get; set; }

        [Column("estado")]
        public string Estado { get; set; } = "ABIERTA";

        [Column("es_per")]
        public bool EsPer { get; set; }

        [Column("tipo_seccion")]
        public string TipoSeccion { get; set; } = "REGULAR";
    }
}
