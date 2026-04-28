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
    public class NotificacionesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public NotificacionesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        private int? GetUserId()
        {
            var str = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(str, out var id)) return id;
            return null;
        }

        /// <summary>
        /// Retorna todas las notificaciones del usuario autenticado.
        /// </summary>
        [HttpGet("me")]
        public async Task<ActionResult<IEnumerable<Notificacion>>> GetMisNotificaciones()
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var notificaciones = await _context.Notificaciones
                .Where(n => n.UsuarioId == userId)
                .OrderByDescending(n => n.FechaCreacion)
                .ToListAsync();

            return Ok(notificaciones);
        }

        /// <summary>
        /// Conteo de notificaciones NO leídas.
        /// </summary>
        [HttpGet("me/no-leidas")]
        public async Task<ActionResult<int>> GetConteoNoLeidas()
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var count = await _context.Notificaciones
                .CountAsync(n => n.UsuarioId == userId && !n.Leida);

            return Ok(new { total = count });
        }

        /// <summary>
        /// Marca una notificación específica como leída.
        /// </summary>
        [HttpPost("me/{id}/leer")]
        public async Task<IActionResult> MarcarLeida(int id)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var notif = await _context.Notificaciones
                .FirstOrDefaultAsync(n => n.IdNotificacion == id && n.UsuarioId == userId);

            if (notif == null) return NotFound();

            notif.Leida = true;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Notificación marcada como leída." });
        }

        /// <summary>
        /// Marca TODAS las notificaciones del usuario como leídas.
        /// </summary>
        [HttpPost("me/leer-todas")]
        public async Task<IActionResult> MarcarTodasLeidas()
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var pendientes = await _context.Notificaciones
                .Where(n => n.UsuarioId == userId && !n.Leida)
                .ToListAsync();

            pendientes.ForEach(n => n.Leida = true);
            await _context.SaveChangesAsync();
            return Ok(new { message = $"{pendientes.Count} notificaciones marcadas como leídas." });
        }

        /// <summary>
        /// Crea una notificación para un usuario. Uso interno / administrador.
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<Notificacion>> PostNotificacion(Notificacion notificacion)
        {
            notificacion.FechaCreacion = DateTime.UtcNow;
            _context.Notificaciones.Add(notificacion);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetMisNotificaciones), new { }, notificacion);
        }

        /// <summary>
        /// Elimina una notificación del usuario autenticado.
        /// </summary>
        [HttpDelete("me/{id}")]
        public async Task<IActionResult> DeleteNotificacion(int id)
        {
            var userId = GetUserId();
            var notif = await _context.Notificaciones
                .FirstOrDefaultAsync(n => n.IdNotificacion == id && n.UsuarioId == userId);

            if (notif == null) return NotFound();

            _context.Notificaciones.Remove(notif);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
