// DTOs/LoginDto.cs
namespace UPTMDigital.API.DTOs
{
    public class LoginDto
    {
        public string NombreUsuario { get; set; } = null!;
        public string Contrasena { get; set; } = null!;
    }

    public class LoginResponseDto
    {
        public string Token { get; set; } = null!;
        public DateTime Expiracion { get; set; }
        public string NombreUsuario { get; set; } = null!;
        public string Rol { get; set; } = null!;
    }
}