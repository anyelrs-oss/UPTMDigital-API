using System.ComponentModel.DataAnnotations;

namespace UPTMDigital.API.Models
{
    public class RegisterDto
    {
        [Required]
        public string Cedula { get; set; } = null!;

        [Required]
        public string Contrasena { get; set; } = null!;
        
        [Required]
        public string Username { get; set; } = null!;
    }
}
