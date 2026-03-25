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

        /// <summary>
        /// Retorna todas las notificaciones del usuario autenticado, ordenadas de más reciente a más antigua.
        /// El frontend usa este endpoint para mostrar el "badgito" rojo y la lista de notificaciones.
        /// </summary>
        [HttpGet("me")]
        public async Task<ActionResult<IEnumerable<Notificacion>>> GetMisNotificaciones()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            if (string.IsNullOrEmpty(username)) return Unauthorized();

            var notificaciones = await _context.Notificaciones
                .Where(n => n.DestinatarioLogin == username)
                .OrderByDescending(n => n.FechaCreacion)
                .ToListAsync();

            return Ok(notificaciones);
        }

        /// <summary>
        /// Retorna solo el conteo de notificaciones NO leídas.
        /// Útil para actualizar el badge sin cargar toda la lista.
        /// </summary>
        [HttpGet("me/no-leidas")]
        public async Task<ActionResult<int>> GetConteoNoLeidas()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            if (string.IsNullOrEmpty(username)) return Unauthorized();

            var count = await _context.Notificaciones
                .CountAsync(n => n.DestinatarioLogin == username && !n.Leida);

            return Ok(new { total = count });
        }

        /// <summary>
        /// Marca una notificación específica como leída.
        /// Se llama cuando el usuario toca una notificación en la lista.
        /// </summary>
        [HttpPost("me/{id}/leer")]
        public async Task<IActionResult> MarcarLeida(int id)
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            if (string.IsNullOrEmpty(username)) return Unauthorized();

            var notif = await _context.Notificaciones
                .FirstOrDefaultAsync(n => n.IdNotificacion == id && n.DestinatarioLogin == username);

            if (notif == null) return NotFound();

            notif.Leida = true;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Notificación marcada como leída." });
        }

        /// <summary>
        /// Marca TODAS las notificaciones del usuario como leídas de una vez.
        /// Útil para el botón "Marcar todas como leídas".
        /// </summary>
        [HttpPost("me/leer-todas")]
        public async Task<IActionResult> MarcarTodasLeidas()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            if (string.IsNullOrEmpty(username)) return Unauthorized();

            var pendientes = await _context.Notificaciones
                .Where(n => n.DestinatarioLogin == username && !n.Leida)
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
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            var notif = await _context.Notificaciones
                .FirstOrDefaultAsync(n => n.IdNotificacion == id && n.DestinatarioLogin == username);

            if (notif == null) return NotFound();

            _context.Notificaciones.Remove(notif);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
