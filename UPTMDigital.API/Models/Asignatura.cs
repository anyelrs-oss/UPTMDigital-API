using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models
{
    [Table("Asignatura")]
    public class Asignatura
    {
        [Key]
        public int IdAsignatura { get; set; }
        public string Codigo { get; set; } = null!;
        public string Nombre { get; set; } = null!;
        public int Creditos { get; set; }
        public string? Departamento { get; set; }

        // --- FK Normalizadas ---
        public int? ProfesorId { get; set; }
        [ForeignKey("ProfesorId")]
        public Profesor? Profesor { get; set; }

        public int? SemestreId { get; set; }
        [ForeignKey("SemestreId")]
        public Semestre? Semestre { get; set; }

        public int? CarreraId { get; set; }
        [ForeignKey("CarreraId")]
        public Carrera? Carrera { get; set; }

        public bool Activo { get; set; } = true;
    }
}