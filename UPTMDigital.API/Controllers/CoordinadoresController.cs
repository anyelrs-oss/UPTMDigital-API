using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class CoordinadoresController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public CoordinadoresController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet("me")]
        public async Task<ActionResult<Coordinador>> GetMe()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var coord = await _context.Coordinadores
                .Include(c => c.Carrera)
                .FirstOrDefaultAsync(c => c.UsuarioId == userId);

            if (coord == null) return NotFound("Perfil de coordinador no encontrado.");
            return coord;
        }

        [Authorize(Roles = "Coordinador,Administrador")]
        [HttpPost("generar-pin")]
        public async Task<IActionResult> GenerarPin([FromBody] PinRequest request)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdStr, out var userId)) return Unauthorized();

            // Desactivar pines anteriores para esta carrera
            var viejos = await _context.PinesAsistencia
                .Where(p => p.CarreraId == request.CarreraId && p.Activo)
                .ToListAsync();
            foreach (var v in viejos) v.Activo = false;

            var rnd = new Random();
            var pin = rnd.Next(100000, 999999).ToString();

            var nuevo = new PinAsistencia
            {
                Pin = pin,
                CarreraId = request.CarreraId,
                CoordinadorId = userId,
                FechaExpiracion = DateTime.UtcNow.AddHours(12),
                Activo = true
            };

            _context.PinesAsistencia.Add(nuevo);
            await _context.SaveChangesAsync();

            return Ok(nuevo);
        }

        [Authorize(Roles = "Administrador")]
        [HttpGet("pines-activos")]
        public async Task<IActionResult> GetPinesActivos()
        {
            var pines = await _context.PinesAsistencia
                .Include(p => p.Carrera)
                .Include(p => p.Coordinador)
                .Where(p => p.Activo && p.FechaExpiracion > DateTime.UtcNow)
                .Select(p => new
                {
                    p.IdPin,
                    p.Pin,
                    p.FechaExpiracion,
                    Carrera = p.Carrera != null ? p.Carrera.Nombre : "General",
                    Coordinador = p.Coordinador != null ? p.Coordinador.NombreUsuario : "Sistema"
                })
                .ToListAsync();

            return Ok(pines);
        }

        public class PinRequest { public int CarreraId { get; set; } }
    }
}
