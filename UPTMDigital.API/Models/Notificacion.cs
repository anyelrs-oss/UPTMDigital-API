using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    /// <summary>
    /// Notificación entregada a un usuario específico de la app.
    /// Tipos: Sistema (mantenimiento, etc.), Academica (nota publicada, etc.), Chat (nuevo mensaje).
    /// </summary>
    [Table("Notificacion")]
    public class Notificacion
    {
        [Key]
        public int IdNotificacion { get; set; }

        // --- FK Normalizada ---
        public int UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        [Required]
        public string Titulo { get; set; } = null!;

        [Required]
        public string Cuerpo { get; set; } = null!;

        /// <summary>Sistema | Academica | Chat | Evaluacion</summary>
        public string Tipo { get; set; } = "Sistema";

        public bool Leida { get; set; } = false;

        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    }
}
