using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    /// <summary>
    /// Solicitud de apertura de un aula/laboratorio.
    /// Flujo: Profesor solicita → Seguridad recibe push → responde "EnCamino" → Completada.
    /// Es un log inmutable: no tiene Activo (nunca se borra).
    /// </summary>
    [Table("SolicitudApertura")]
    public class SolicitudApertura
    {
        [Key]
        public int IdSolicitud { get; set; }

        // --- FK: Qué aula ---
        public int AulaId { get; set; }
        [ForeignKey("AulaId")]
        public Aula? Aula { get; set; }

        // --- FK: Quién solicita ---
        public int ProfesorId { get; set; }
        [ForeignKey("ProfesorId")]
        public Profesor? Profesor { get; set; }

        // --- FK: Quién responde (seguridad) ---
        public int? SeguridadUsuarioId { get; set; }
        [ForeignKey("SeguridadUsuarioId")]
        public Usuario? SeguridadUsuario { get; set; }

        /// <summary>Estado: "Pendiente", "EnCamino", "Completada", "Cancelada"</summary>
        [Required]
        public string Estado { get; set; } = "Pendiente";

        public string? Motivo { get; set; } // Motivo opcional de la solicitud

        public DateTime FechaSolicitud { get; set; } = DateTime.UtcNow;
        public DateTime? FechaRespuesta { get; set; }
        public DateTime? FechaCompletada { get; set; }
    }
}
