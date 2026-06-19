using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MensajesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public MensajesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Retorna la lista de chats del usuario autenticado (Asignaturas + Privados).
        /// </summary>
        [Authorize]
        [HttpGet("mis-chats")]
        public async Task<IActionResult> GetMisChats()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var role = User.FindFirst(ClaimTypes.Role)?.Value;

            // 1. Obtener datos básicos del usuario
            var user = await _context.Usuarios.FindAsync(userId);
            if (user == null) return NotFound();

            List<int> asignaturaIds = new List<int>();
            int? userCarreraId = null;

            if (role == "Profesor")
            {
                var profesor = await _context.Profesores.AsNoTracking().FirstOrDefaultAsync(p => p.UsuarioId == userId);
                if (profesor != null)
                {
                    asignaturaIds = await _context.Asignaturas.AsNoTracking().Where(a => a.ProfesorId == profesor.IdProfesor).Select(a => a.IdAsignatura).ToListAsync();
                    // Buscamos su carrera (departamento)
                    userCarreraId = (await _context.Carreras.FirstOrDefaultAsync(c => c.Nombre == profesor.Departamento))?.IdCarrera;
                }
            }
            else if (role == "Coordinador")
            {
                var coord = await _context.Coordinadores.AsNoTracking().FirstOrDefaultAsync(c => c.UsuarioId == userId);
                if (coord != null) userCarreraId = coord.CarreraId;
            }
            else
            {
                var estudiante = await _context.Estudiantes.AsNoTracking().FirstOrDefaultAsync(e => e.UsuarioId == userId);
                if (estudiante != null)
                {
                    asignaturaIds = await _context.Inscripciones.AsNoTracking().Where(i => i.EstudianteId == estudiante.IdEstudiante).Select(i => i.AsignaturaId).ToListAsync();
                    userCarreraId = estudiante.CarreraId;
                }
            }

            // 2. Obtener chat de Carrera (Si tiene una carrera asignada)
            var chatCarrera = new List<object>();
            if (userCarreraId.HasValue)
            {
                var carrera = await _context.Carreras.FindAsync(userCarreraId.Value);
                if (carrera != null)
                {
                    var ultimo = await _context.Mensajes
                        .Where(m => m.TipoChat == "Carrera" && m.CarreraId == userCarreraId.Value)
                        .OrderByDescending(m => m.FechaEnvio)
                        .Select(m => new { m.Contenido, m.FechaEnvio, m.EmisorNombre })
                        .FirstOrDefaultAsync();

                    chatCarrera.Add(new
                    {
                        tipo = "Carrera",
                        id = carrera.IdCarrera,
                        nombre = "SALA: " + carrera.Nombre,
                        ultimoMensaje = ultimo
                    });
                }
            }

            // 3. Obtener chats de asignaturas
            var chatsAsignatura = await _context.Asignaturas
                .AsNoTracking()
                .Where(a => asignaturaIds.Contains(a.IdAsignatura))
                .Select(a => new
                {
                    tipo = "Asignatura",
                    id = a.IdAsignatura,
                    nombre = a.Nombre,
                    ultimoMensaje = _context.Mensajes
                        .Where(m => m.AsignaturaId == a.IdAsignatura && m.TipoChat == "Asignatura")
                        .OrderByDescending(m => m.FechaEnvio)
                        .Select(m => new { m.Contenido, m.FechaEnvio, m.EmisorNombre })
                        .FirstOrDefault()
                })
                .ToListAsync();

            // 3. Obtener chats privados (Donde el usuario es emisor o receptor) - OPTIMIZADO: Sin N+1 queries
            var chatsPrivados = await _context.Mensajes
                .AsNoTracking()
                .Where(m => m.TipoChat == "Privado" && (m.UsuarioId == userId || m.ReceptorUsuarioId == userId))
                .GroupBy(m => m.UsuarioId == userId ? m.ReceptorUsuarioId : m.UsuarioId)
                .Select(g => new
                {
                    peerId = g.Key,
                    ultimoMensaje = g.OrderByDescending(m => m.FechaEnvio)
                        .Select(m => new { m.Contenido, m.FechaEnvio, m.EmisorNombre })
                        .FirstOrDefault()
                })
                .ToListAsync();

            // Obtener datos de usuarios en UNA sola query
            var peerIds = chatsPrivados.Where(c => c.peerId.HasValue).Select(c => c.peerId.Value).ToList();
            var usuarios = await _context.Usuarios
                .AsNoTracking()
                .Where(u => peerIds.Contains(u.IdUsuario))
                .ToDictionaryAsync(u => u.IdUsuario, u => u);

            var chatsPrivadosFormatted = new List<object>();
            foreach (var chat in chatsPrivados)
            {
                if (chat.peerId.HasValue && usuarios.TryGetValue(chat.peerId.Value, out var peer))
                {
                    chatsPrivadosFormatted.Add(new
                    {
                        tipo = "Privado",
                        id = peer.IdUsuario,
                        nombre = peer.NombreUsuario,
                        ultimoMensaje = chat.ultimoMensaje
                    });
                }
            }

            var allChats = chatCarrera.Concat(chatsAsignatura.Cast<object>()).Concat(chatsPrivadosFormatted).ToList();
            return Ok(allChats);
        }

        [Authorize]
        [HttpGet("{asignaturaId}")]
        public async Task<ActionResult<IEnumerable<Mensaje>>> GetMensajes(int asignaturaId)
        {
            return await _context.Mensajes
                .AsNoTracking()
                .Where(m => m.AsignaturaId == asignaturaId && m.TipoChat == "Asignatura")
                .OrderByDescending(m => m.FechaEnvio)
                .Take(100)
                .OrderBy(m => m.FechaEnvio)
                .ToListAsync();
        }

        [Authorize]
        [HttpGet("carrera/{carreraId}")]
        public async Task<ActionResult<IEnumerable<Mensaje>>> GetMensajesCarrera(int carreraId)
        {
            return await _context.Mensajes
                .AsNoTracking()
                .Where(m => m.CarreraId == carreraId && m.TipoChat == "Carrera")
                .OrderByDescending(m => m.FechaEnvio)
                .Take(100)
                .OrderBy(m => m.FechaEnvio)
                .ToListAsync();
        }

        [Authorize]
        [HttpGet("privado/{peerUserId}")]
        public async Task<ActionResult<IEnumerable<Mensaje>>> GetMensajesPrivados(int peerUserId)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdStr, out var userId)) return Unauthorized();

            return await _context.Mensajes
                .AsNoTracking()
                .Where(m => m.TipoChat == "Privado" &&
                      ((m.UsuarioId == userId && m.ReceptorUsuarioId == peerUserId) ||
                       (m.UsuarioId == peerUserId && m.ReceptorUsuarioId == userId)))
                .OrderByDescending(m => m.FechaEnvio)
                .Take(100)
                .OrderBy(m => m.FechaEnvio)
                .ToListAsync();
        }

        /// <summary>
        /// Envía un mensaje en el chat (Asignatura, Carrera o Privado).
        /// </summary>
        [Authorize]
        [HttpPost]
        public async Task<ActionResult<Mensaje>> PostMensaje(Mensaje mensaje)
        {
            try
            {
                // Set UsuarioId from JWT
                var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (!string.IsNullOrEmpty(userIdStr) && int.TryParse(userIdStr, out var userId))
                {
                    mensaje.UsuarioId = userId;
                }

                // Autopopular EmisorNombre si viene vacío o nulo
                if (string.IsNullOrEmpty(mensaje.EmisorNombre) && mensaje.UsuarioId > 0)
                {
                    var user = await _context.Usuarios.FindAsync(mensaje.UsuarioId);
                    mensaje.EmisorNombre = user?.NombreUsuario ?? "Usuario";
                }

                mensaje.FechaEnvio = DateTime.UtcNow;
                _context.Mensajes.Add(mensaje);
                await _context.SaveChangesAsync();

                return Ok(mensaje);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ERROR PostMensaje] Exception: {ex.Message}");
                Console.WriteLine($"[ERROR PostMensaje] StackTrace: {ex.StackTrace}");
                var fullMessage = ex.Message;
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"[ERROR PostMensaje] Inner: {ex.InnerException.Message}");
                    fullMessage += $" -> {ex.InnerException.Message}";
                }
                return StatusCode(500, $"Error interno al enviar mensaje: {fullMessage}");
            }
        }
    }
}
