using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("SolicitudApertura")]
    public class SolicitudApertura
    {
        [Key]
        public int IdSolicitud { get; set; }

        public int AulaId { get; set; }
        [ForeignKey("AulaId")]
        public Aula? Aula { get; set; }

        public int ProfesorId { get; set; }
        [ForeignKey("ProfesorId")]
        public Profesor? Profesor { get; set; }

        public int? PersonalSeguridadId { get; set; }
        [ForeignKey("PersonalSeguridadId")]
        public Usuario? PersonalSeguridad { get; set; }

        public DateTime FechaSolicitud { get; set; } = DateTime.UtcNow;
        public DateTime? FechaAtencion { get; set; }
        public DateTime? FechaCompletada { get; set; }

        // Estado: Pendiente, EnCamino, Completada, Cancelada
        public string Estado { get; set; } = "Pendiente";

        public string? Motivo { get; set; }
    }
}
