using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Coordinador")]
    public class Coordinador
    {
        [Key]
        public int IdCoordinador { get; set; }

        public int UsuarioId { get; set; }
        [ForeignKey("UsuarioId")]
        public Usuario? Usuario { get; set; }

        public int? CarreraId { get; set; }
        [ForeignKey("CarreraId")]
        public Carrera? Carrera { get; set; }

        public string? Nombres { get; set; }
        public string? Apellidos { get; set; }

        public bool Activo { get; set; } = true;
    }
}
