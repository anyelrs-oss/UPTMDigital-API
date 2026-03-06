
namespace UPTMDigital.API.DTOs
{
    public class ControlAccesoDto
    {
        public string Cedula { get; set; } = null!;
        public string Tipo { get; set; } = null!; // "Entrada", "Salida"
        public string? Ubicacion { get; set; }
    }
}
