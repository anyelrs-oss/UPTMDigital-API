using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Perfil de docente en Daree.
    /// Tabla: docentes | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("docentes")]
    public class DareeDocente
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("cedula")]
        public string Cedula { get; set; } = null!;

        [Column("nombres")]
        public string Nombres { get; set; } = null!;

        [Column("apellidos")]
        public string Apellidos { get; set; } = null!;

        [Column("correo")]
        public string? Correo { get; set; }

        [Column("telefono")]
        public string? Telefono { get; set; }

        [Column("profesion")]
        public string? Profesion { get; set; }

        [Column("especialidad")]
        public string? Especialidad { get; set; }

        [Column("activo")]
        public int? Activo { get; set; } = 1;

        [Column("fecha_registro")]
        public DateTime? FechaRegistro { get; set; }

        [Column("pnf_id")]
        public int? PnfId { get; set; }

        [Column("estatus")]
        public string? Estatus { get; set; } = "ACTIVO";
    }
}
