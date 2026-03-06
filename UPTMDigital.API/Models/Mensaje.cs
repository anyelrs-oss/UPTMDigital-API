using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Mensaje")]
    public class Mensaje
    {
        [Key]
        public int IdMensaje { get; set; }
        public int AsignaturaId { get; set; }
        public string Contenido { get; set; } = null!;
        public DateTime FechaEnvio { get; set; }
        public string EmisorNombre { get; set; } = null!;
        // Could link to Usuario or Estudiante/Profesor, but name is enough for simple chat
    }
}
