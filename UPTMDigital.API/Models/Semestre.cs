using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Semestre")]
    public class Semestre
    {
        [Key]
        public int IdSemestre { get; set; }
        public string Nombre { get; set; } = null!;
    }
}
