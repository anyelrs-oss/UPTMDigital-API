using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("GlobalSetting")]
    public class GlobalSetting
    {
        [Key]
        public string Clave { get; set; } = null!; // Ej: "HabilitarSubidaNotas"
        public string Valor { get; set; } = null!; // "true", "false", "2024-01-01"
        public DateTime UltimaActualizacion { get; set; } = DateTime.UtcNow;
    }
}
