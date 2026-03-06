using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Carrera")]
    public class Carrera
    {
        [Key]
        public int IdCarrera { get; set; }
        public string Nombre { get; set; } = null!;
    }
}
