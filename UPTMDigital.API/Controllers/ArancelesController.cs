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
    public class ArancelesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public ArancelesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // POST: api/aranceles/validar
        [HttpPost("validar")]
        public async Task<IActionResult> ValidarArancel([FromBody] ArancelRequest request)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            int? userId = int.TryParse(userIdStr, out var id) ? id : null;

            // 1. Registrar validación
            var validacion = new ArancelValidacion
            {
                CedulaEstudiante = request.Cedula,
                NumeroFactura = request.NumeroFactura,
                SecretariaId = userId,
                FechaValidacion = DateTime.UtcNow
            };

            _context.ArancelesValidaciones.Add(validacion);

            // 2. Marcar estudiante como solvente
            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula == request.Cedula);
            if (estudiante != null)
            {
                estudiante.EstadoArancel = true;
            }

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Arancel validado y solvencia actualizada." });
        }

        // GET: api/aranceles/status/{cedula}
        [HttpGet("status/{cedula}")]
        public async Task<IActionResult> GetStatus(string cedula)
        {
            var estudiante = await _context.Estudiantes
                .Select(e => new { e.Cedula, e.Nombres, e.Apellidos, e.EstadoArancel })
                .FirstOrDefaultAsync(e => e.Cedula == cedula);

            if (estudiante == null) return NotFound();

            return Ok(estudiante);
        }

        public class ArancelRequest
        {
            public string Cedula { get; set; } = null!;
            public string NumeroFactura { get; set; } = null!;
        }
    }
}
