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

        /// <summary>NombreUsuario del destinatario (FK a Usuario).</summary>
        [Required]
        public string DestinatarioLogin { get; set; } = null!;

        [Required]
        public string Titulo { get; set; } = null!;

        [Required]
        public string Cuerpo { get; set; } = null!;

        /// <summary>Sistema | Academica | Chat</summary>
        public string Tipo { get; set; } = "Sistema";

        public bool Leida { get; set; } = false;

        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    }
}
