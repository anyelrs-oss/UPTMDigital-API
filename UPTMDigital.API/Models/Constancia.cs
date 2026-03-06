using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Constancia")]
    public class Constancia
    {
        [Key]
        public int IdConstancia { get; set; }
        public int EstudianteId { get; set; }
        public string TipoConstancia { get; set; } = null!;
        public string? Estado { get; set; }
        public DateTime? FechaSolicitud { get; set; }
        public string? CodigoQR { get; set; }
        public string? ArchivoUrl { get; set; }

        public Estudiante Estudiante { get; set; } = null!;
    }
}