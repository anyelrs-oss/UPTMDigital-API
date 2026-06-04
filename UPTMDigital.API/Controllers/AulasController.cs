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
    public class AulasController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public AulasController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // GET: api/aulas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Aula>>> GetAulas([FromQuery] string? edificio, [FromQuery] string? estado)
        {
            var query = _context.Aulas.Where(a => a.Activo);

            if (!string.IsNullOrEmpty(edificio))
                query = query.Where(a => a.Edificio == edificio);

            if (!string.IsNullOrEmpty(estado))
                query = query.Where(a => a.Estado == estado);

            return await query.OrderBy(a => a.Nombre).ToListAsync();
        }

        // POST: api/aulas/solicitar-apertura
        [HttpPost("solicitar-apertura")]
        public async Task<IActionResult> SolicitarApertura([FromBody] SolicitudRequest request)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var profesor = await _context.Profesores.FirstOrDefaultAsync(p => p.UsuarioId == userId);
            if (profesor == null) return BadRequest("Usuario no es profesor.");

            var aula = await _context.Aulas.FindAsync(request.AulaId);
            if (aula == null) return NotFound("Aula no encontrada.");

            var nuevaSolicitud = new SolicitudApertura
            {
                AulaId = request.AulaId,
                ProfesorId = profesor.IdProfesor,
                Motivo = request.Motivo,
                Estado = "Pendiente",
                FechaSolicitud = DateTime.UtcNow
            };

            _context.SolicitudApertura.Add(nuevaSolicitud);
            await _context.SaveChangesAsync();

            return Ok(nuevaSolicitud);
        }

        // GET: api/aulas/solicitudes
        [HttpGet("solicitudes")]
        public async Task<ActionResult<IEnumerable<SolicitudApertura>>> GetSolicitudes([FromQuery] string? estado)
        {
            var query = _context.SolicitudApertura
                .Include(s => s.Aula)
                .Include(s => s.Profesor)
                .AsQueryable();

            if (!string.IsNullOrEmpty(estado))
                query = query.Where(s => s.Estado == estado);

            return await query.OrderByDescending(s => s.FechaSolicitud).ToListAsync();
        }

        [HttpPut("solicitudes/{id}/en-camino")]
        public async Task<IActionResult> MarcarEnCamino(int id)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var solicitud = await _context.SolicitudApertura.FindAsync(id);
            if (solicitud == null) return NotFound();

            solicitud.Estado = "EnCamino";
            solicitud.PersonalSeguridadId = userId;
            solicitud.FechaAtencion = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(solicitud);
        }

        [HttpPut("solicitudes/{id}/completar")]
        public async Task<IActionResult> CompletarApertura(int id)
        {
            var solicitud = await _context.SolicitudApertura.Include(s => s.Aula).FirstOrDefaultAsync(s => s.IdSolicitud == id);
            if (solicitud == null) return NotFound();

            solicitud.Estado = "Completada";
            solicitud.FechaCompletada = DateTime.UtcNow;

            if (solicitud.Aula != null)
            {
                solicitud.Aula.Estado = "Ocupada";
                solicitud.Aula.HoraApertura = DateTime.UtcNow;
                solicitud.Aula.ProfesorActualId = solicitud.ProfesorId;
            }

            await _context.SaveChangesAsync();
            return Ok(solicitud);
        }

        [HttpPut("{id}/liberar")]
        public async Task<IActionResult> LiberarAula(int id)
        {
            var aula = await _context.Aulas.FindAsync(id);
            if (aula == null) return NotFound();

            aula.Estado = "Disponible";
            aula.HoraApertura = null;
            aula.ProfesorActualId = null;

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Aula liberada." });
        }

        public class SolicitudRequest
        {
            public int AulaId { get; set; }
            public string? Motivo { get; set; }
        }
    }
}
