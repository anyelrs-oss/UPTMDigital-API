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
        public int? Semestre { get; set; }
        public string? Departamento { get; set; }
        public int? ProfesorId { get; set; }

        public Profesor? Profesor { get; set; }
    }
}