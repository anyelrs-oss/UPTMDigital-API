using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("PinAsistencia")]
    public class PinAsistencia
    {
        [Key]
        public int IdPin { get; set; }

        public string Pin { get; set; } = null!;

        public DateTime FechaExpiracion { get; set; }

        public int? CarreraId { get; set; }
        [ForeignKey("CarreraId")]
        public Carrera? Carrera { get; set; }

        public int? CoordinadorId { get; set; }
        [ForeignKey("CoordinadorId")]
        public Usuario? Coordinador { get; set; }

        public bool Activo { get; set; } = true;
    }
}
