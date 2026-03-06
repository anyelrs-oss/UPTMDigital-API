using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Anuncio")]
    public class Anuncio
    {
        [Key]
        public int IdAnuncio { get; set; }
        public string Titulo { get; set; } = null!;
        public string Contenido { get; set; } = null!;
        public DateTime FechaPublicacion { get; set; }
        public string? Autor { get; set; }
    }
}
