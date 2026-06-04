using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Aula")]
    public class Aula
    {
        [Key]
        public int IdAula { get; set; }
        public string Nombre { get; set; } = null!;
        public string Edificio { get; set; } = null!;
        public string Piso { get; set; } = null!;

        // Estado: Disponible, Ocupada, Mantenimiento, Reservada
        public string Estado { get; set; } = "Disponible";

        public DateTime? HoraApertura { get; set; }

        public int? ProfesorActualId { get; set; }
        [ForeignKey("ProfesorActualId")]
        public Profesor? ProfesorActual { get; set; }

        public bool Activo { get; set; } = true;
    }
}
