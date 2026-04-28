using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Mensaje")]
    public class Mensaje
    {
        [Key]
        public int IdMensaje { get; set; }

        // --- FK Normalizadas ---
        public int AsignaturaId { get; set; }
        [ForeignKey("AsignaturaId")]
        public Asignatura? Asignatura { get; set; }

        public int UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        public string Contenido { get; set; } = null!;
        public DateTime FechaEnvio { get; set; }

        /// <summary>
        /// Nombre del emisor (se puede calcular desde Usuario, pero se guarda
        /// para mostrar rápido sin JOIN y mantener historial si el usuario cambia nombre).
        /// </summary>
        public string EmisorNombre { get; set; } = null!;
    }
}
