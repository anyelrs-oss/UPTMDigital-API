using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    /// <summary>
    /// Perfil extendido para usuarios con rol Coordinador.
    /// Vincula jerárquicamente al usuario con una carrera específica.
    /// </summary>
    [Table("Coordinador")]
    public class Coordinador
    {
        [Key]
        public int IdCoordinador { get; set; }

        // --- FK Normalizadas ---
        public int UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        public int CarreraId { get; set; }
        [ForeignKey("CarreraId")]
        public Carrera? Carrera { get; set; }

        public string? Departamento { get; set; }

        public bool Activo { get; set; } = true;
    }
}
