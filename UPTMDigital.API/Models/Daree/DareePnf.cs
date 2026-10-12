using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Programas Nacionales de Formación (carreras) en Daree.
    /// Tabla: pnfs | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("pnfs")]
    public class DareePnf
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("codigo")]
        public string Codigo { get; set; } = null!;

        [Column("nombre")]
        public string Nombre { get; set; } = null!;

        [Column("color_ui")]
        public string? ColorUi { get; set; }

        [Column("activo")]
        public bool Activo { get; set; }

        [Column("color_hex")]
        public string? ColorHex { get; set; }

        [Column("color")]
        public string? Color { get; set; }
    }
}
