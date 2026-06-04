using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("ArancelValidacion")]
    public class ArancelValidacion
    {
        [Key]
        public int IdValidacion { get; set; }

        public string CedulaEstudiante { get; set; } = null!;

        public string NumeroFactura { get; set; } = null!;

        public DateTime FechaValidacion { get; set; } = DateTime.UtcNow;

        public int? SecretariaId { get; set; }
        [ForeignKey("SecretariaId")]
        public Usuario? Secretaria { get; set; }

        public string MetodoPago { get; set; } = "Transferencia";
    }
}
