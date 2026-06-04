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

        // --- Nuevos Campos Fase 6 (Cartelera Jerárquica) ---

        // Si es null, va dirigido a todos
        public int? CarreraId { get; set; }
        [ForeignKey("CarreraId")]
        public Carrera? Carrera { get; set; }

        // Si es null, va dirigido a todos los roles
        public int? RolId { get; set; }
        [ForeignKey("RolId")]
        public Rol? Rol { get; set; }

        // Prioridad: Normal, Urgente, Critica
        public string Prioridad { get; set; } = "Normal";

        // Trimestre dirigido (Opcional)
        public string? Trimestre { get; set; }

        public bool Activo { get; set; } = true;
    }
}
