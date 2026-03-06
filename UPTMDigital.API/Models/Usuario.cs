using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Usuario")]
    public class Usuario
    {
        [Key]
        public int IdUsuario { get; set; }
        public string NombreUsuario { get; set; } = null!;
        public string ContrasenaHash { get; set; } = null!;
        public string? Cedula { get; set; }
        public int RolId { get; set; }
        public bool EstadoCuenta { get; set; } = true;
        public DateTime? UltimoAcceso { get; set; }

        public Rol Rol { get; set; } = null!;
    }
}