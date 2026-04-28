using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("ControlAcceso")]
    public class ControlAcceso
    {
        [Key]
        public int Id { get; set; }

        // --- FK Normalizadas ---
        /// <summary>Usuario que fue escaneado (estudiante, profesor, etc.)</summary>
        public int? UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        /// <summary>Guardia que realizó el escaneo.</summary>
        public int? PersonalSeguridadId { get; set; }
        [ForeignKey("PersonalSeguridadId")]
        public Usuario? PersonalSeguridad { get; set; }

        /// <summary>Cédula escaneada — se mantiene para búsqueda rápida y cuando
        /// el QR viene de un sistema externo (carnetización).</summary>
        [Required]
        [MaxLength(20)]
        public string Cedula { get; set; } = null!;

        public DateTime FechaHora { get; set; } = DateTime.Now;

        [Required]
        [MaxLength(10)]
        public string Tipo { get; set; } = null!; // "Entrada" or "Salida"

        [MaxLength(50)]
        public string? Ubicacion { get; set; }
    }
}
