using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Periodo")]
    public class Periodo
    {
        [Key]
        public int IdPeriodo { get; set; }
        public string Nombre { get; set; } = null!;
        public bool Activo { get; set; }
    }
}
