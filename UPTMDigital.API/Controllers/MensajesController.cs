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
        private readonly IServiceScopeFactory _scopeFactory;

        public MensajesController(UPTMDigitalContext context, IServiceScopeFactory scopeFactory)
        {
            _context = context;
            _scopeFactory = scopeFactory;
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
        /// Al guardar, crea Notificaciones para los destinatarios.
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

                // --- Crear notificaciones en segundo plano (no bloquear respuesta) ---
                var scopeFactory = _scopeFactory;
                _ = Task.Run(async () =>
                {
                    using var scope = scopeFactory.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<UPTMDigitalContext>();
                    await _crearNotificacionesBackground(db, mensaje);
                });

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

        /// <summary>
        /// Crea notificaciones en BD para los destinatarios de un mensaje (ejecutado en background).
        /// </summary>
        private static async Task _crearNotificacionesBackground(UPTMDigitalContext _context, Mensaje mensaje)
        {
            try
            {
                var preview = mensaje.Contenido?.Length > 80
                    ? mensaje.Contenido.Substring(0, 80) + "..."
                    : mensaje.Contenido ?? "";
                var emisor = mensaje.EmisorNombre ?? "Alguien";

                var recipientIds = new List<int>();

                if (mensaje.TipoChat == "Privado" && mensaje.ReceptorUsuarioId.HasValue)
                {
                    // Chat privado: notificar al receptor
                    recipientIds.Add(mensaje.ReceptorUsuarioId.Value);
                }
                else if (mensaje.TipoChat == "Carrera" && mensaje.CarreraId.HasValue)
                {
                    // Chat de carrera: notificar a estudiantes + profesores + coordinador
                    var estudianteIds = await _context.Estudiantes
                        .Where(e => e.CarreraId == mensaje.CarreraId.Value && e.UsuarioId != null)
                        .Select(e => e.UsuarioId!.Value)
                        .ToListAsync();
                    recipientIds.AddRange(estudianteIds);

                    var coordIds = await _context.Coordinadores
                        .Where(c => c.CarreraId == mensaje.CarreraId.Value)
                        .Select(c => c.UsuarioId)
                        .ToListAsync();
                    recipientIds.AddRange(coordIds);

                    // Profesores del departamento de la carrera
                    var carrera = await _context.Carreras.FindAsync(mensaje.CarreraId.Value);
                    if (carrera != null)
                    {
                        var profIds = await _context.Profesores
                            .Where(p => p.Departamento == carrera.Nombre && p.UsuarioId != null)
                            .Select(p => p.UsuarioId!.Value)
                            .ToListAsync();
                        recipientIds.AddRange(profIds);
                    }
                }
                else if (mensaje.TipoChat == "Asignatura" && mensaje.AsignaturaId.HasValue)
                {
                    // Chat de asignatura: notificar a inscritos + profesor
                    var inscritosIds = await _context.Inscripciones
                        .Where(i => i.AsignaturaId == mensaje.AsignaturaId.Value && i.Estudiante != null && i.Estudiante.UsuarioId != null)
                        .Select(i => i.Estudiante!.UsuarioId!.Value)
                        .ToListAsync();
                    recipientIds.AddRange(inscritosIds);

                    var asignatura = await _context.Asignaturas.FindAsync(mensaje.AsignaturaId.Value);
                    if (asignatura?.ProfesorId != null)
                    {
                        var profUserId = await _context.Profesores
                            .Where(p => p.IdProfesor == asignatura.ProfesorId && p.UsuarioId != null)
                            .Select(p => p.UsuarioId!.Value)
                            .FirstOrDefaultAsync();
                        if (profUserId > 0) recipientIds.Add(profUserId);
                    }
                }

                // Quitar al emisor y duplicados
                recipientIds = recipientIds
                    .Where(id => id != mensaje.UsuarioId && id > 0)
                    .Distinct()
                    .ToList();

                // Crear notificaciones (batch)
                var notificaciones = recipientIds.Select(rid => new Notificacion
                {
                    UsuarioId = rid,
                    Titulo = $"💬 {emisor}",
                    Cuerpo = preview,
                    Tipo = "Chat",
                    Leida = false,
                    FechaCreacion = DateTime.UtcNow,
                }).ToList();

                if (notificaciones.Any())
                {
                    _context.Notificaciones.AddRange(notificaciones);
                    await _context.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                // No bloquear el envío del mensaje si falla la notificación
                Console.WriteLine($"[WARN] Error creando notificaciones: {ex.Message}");
            }
        }
    }
}
