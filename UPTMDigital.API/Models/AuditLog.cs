using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("AuditLog")]
    public class AuditLog
    {
        [Key]
        public int IdAudit { get; set; }
        public int? UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }
        public string Accion { get; set; } = null!; // POST, PUT, DELETE
        public string Ruta { get; set; } = null!;
        public string IP { get; set; } = null!;
        public DateTime Fecha { get; set; } = DateTime.UtcNow;
        public string? Detalles { get; set; } // JSON or summary of changes
        public string? MotivoJustificado { get; set; } // Specific for Soft Delete
    }
}
