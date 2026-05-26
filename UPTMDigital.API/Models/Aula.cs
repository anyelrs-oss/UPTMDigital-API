using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    /// <summary>
    /// Representa un espacio físico de la universidad (aula, laboratorio, taller).
    /// Los profesores pueden solicitar su apertura al personal de seguridad.
    /// </summary>
    [Table("Aula")]
    public class Aula
    {
        [Key]
        public int IdAula { get; set; }

        [Required]
        public string Nombre { get; set; } = string.Empty; // e.g., "Lab Computación 01"

        public string? Edificio { get; set; } // e.g., "Bloque A"

        public string? Piso { get; set; }

        /// <summary>Estado actual: "Disponible", "Ocupada", "Mantenimiento"</summary>
        public string Estado { get; set; } = "Disponible";

        /// <summary>Profesor que actualmente tiene el aula ocupada (nullable).</summary>
        public int? ProfesorActualId { get; set; }
        [ForeignKey("ProfesorActualId")]
        public Profesor? ProfesorActual { get; set; }

        public DateTime? HoraApertura { get; set; }

        public bool Activo { get; set; } = true;
    }
}
