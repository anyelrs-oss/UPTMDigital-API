using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Catálogo de aulas físicas (edificios y salones).
    /// Tabla: aulas_catalogo | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("aulas_catalogo")]
    public class DareeAula
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("codigo")]
        public string Codigo { get; set; } = null!;

        [Column("nombre")]
        public string? Nombre { get; set; }

        [Column("edificio")]
        public string? Edificio { get; set; }

        [Column("capacidad")]
        public int Capacidad { get; set; } = 35;

        [Column("tipo")]
        public string Tipo { get; set; } = "AULA";

        [Column("activo")]
        public bool Activo { get; set; }
    }
}
