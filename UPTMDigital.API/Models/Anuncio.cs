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

        // --- FK Normalizada ---
        public int? UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        /// <summary>Nombre del autor (cache para mostrar sin JOIN).</summary>
        public string? Autor { get; set; }

        public bool Activo { get; set; } = true;
    }
}
