using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;
using System.Security.Claims;

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

        // ═══════════════════════════════════════════════════
        // AULAS — CRUD Básico
        // ═══════════════════════════════════════════════════

        /// <summary>Lista todas las aulas con su estado actual.</summary>
        [HttpGet]
        public async Task<IActionResult> GetAulas([FromQuery] string? edificio, [FromQuery] string? estado)
        {
            var query = _context.Aulas.Include(a => a.ProfesorActual).AsQueryable();

            if (!string.IsNullOrEmpty(edificio))
                query = query.Where(a => a.Edificio != null && a.Edificio.ToLower().Contains(edificio.ToLower()));

            if (!string.IsNullOrEmpty(estado))
                query = query.Where(a => a.Estado == estado);

            var aulas = await query
                .OrderBy(a => a.Edificio).ThenBy(a => a.Nombre)
                .Select(a => new
                {
                    a.IdAula,
                    a.Nombre,
                    a.Edificio,
                    a.Piso,
                    a.Estado,
                    a.HoraApertura,
                    profesorActual = a.ProfesorActual != null
                        ? $"{a.ProfesorActual.Nombres} {a.ProfesorActual.Apellidos}"
                        : null
                })
                .ToListAsync();

            return Ok(aulas);
        }

        /// <summary>Crear una nueva aula (Admin/Coordinador).</summary>
        [HttpPost]
        public async Task<IActionResult> CrearAula([FromBody] AulaCreateDto dto)
        {
            var aula = new Aula
            {
                Nombre = dto.Nombre,
                Edificio = dto.Edificio,
                Piso = dto.Piso,
                Estado = "Disponible"
            };

            _context.Aulas.Add(aula);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetAulas), new { id = aula.IdAula }, new
            {
                message = "Aula creada exitosamente.",
                aula.IdAula,
                aula.Nombre
            });
        }

        // ═══════════════════════════════════════════════════
        // SOLICITUDES DE APERTURA — Flujo completo
        // ═══════════════════════════════════════════════════

        /// <summary>
        /// Profesor solicita apertura de un aula.
        /// Crea solicitud en estado "Pendiente".
        /// TODO: Enviar push a seguridad vía Firebase Cloud Messaging.
        /// </summary>
        [HttpPost("solicitar-apertura")]
        public async Task<IActionResult> SolicitarApertura([FromBody] SolicitudAperturaDto dto)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            // Verificar que el usuario sea profesor
            var profesor = await _context.Profesores
                .FirstOrDefaultAsync(p => p.UsuarioId == userId);

            if (profesor == null)
                return Forbid("Solo profesores pueden solicitar apertura de aulas.");

            // Verificar que el aula exista
            var aula = await _context.Aulas.FindAsync(dto.AulaId);
            if (aula == null) return NotFound("Aula no encontrada.");

            // Verificar que no haya solicitud pendiente para esta aula
            var solicitudExistente = await _context.SolicitudesApertura
                .AnyAsync(s => s.AulaId == dto.AulaId
                            && (s.Estado == "Pendiente" || s.Estado == "EnCamino"));

            if (solicitudExistente)
                return BadRequest(new { message = "Ya existe una solicitud activa para esta aula." });

            var solicitud = new SolicitudApertura
            {
                AulaId = dto.AulaId,
                ProfesorId = profesor.IdProfesor,
                Estado = "Pendiente",
                Motivo = dto.Motivo,
                FechaSolicitud = DateTime.UtcNow
            };

            _context.SolicitudesApertura.Add(solicitud);

            // Registrar notificación para todos los usuarios de seguridad
            var seguridadUsuarios = await _context.Usuarios
                .Include(u => u.Rol)
                .Where(u => u.Rol != null && u.Rol.NombreRol == "Seguridad")
                .Select(u => u.IdUsuario)
                .ToListAsync();

            foreach (var segId in seguridadUsuarios)
            {
                _context.Notificaciones.Add(new Notificacion
                {
                    UsuarioId = segId,
                    Titulo = "🔓 Solicitud de Apertura",
                    Cuerpo = $"El Prof. {profesor.Nombres} {profesor.Apellidos} solicita abrir {aula.Nombre}. Motivo: {dto.Motivo ?? "Sin especificar"}",
                    Tipo = "SolicitudApertura",
                    Leida = false,
                    FechaCreacion = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();

            // TODO: Trigger Firebase Cloud Messaging push notification here
            // await _fcmService.SendToTopic("seguridad", title, body);

            return Ok(new
            {
                message = "Solicitud de apertura enviada. Seguridad ha sido notificada.",
                solicitudId = solicitud.IdSolicitud,
                estado = solicitud.Estado
            });
        }

        /// <summary>
        /// Seguridad marca que va en camino a abrir el aula.
        /// </summary>
        [HttpPut("solicitudes/{id}/en-camino")]
        public async Task<IActionResult> MarcarEnCamino(int id)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var solicitud = await _context.SolicitudesApertura
                .Include(s => s.Aula)
                .Include(s => s.Profesor)
                .FirstOrDefaultAsync(s => s.IdSolicitud == id);

            if (solicitud == null) return NotFound();
            if (solicitud.Estado != "Pendiente")
                return BadRequest(new { message = $"La solicitud ya está en estado '{solicitud.Estado}'." });

            solicitud.Estado = "EnCamino";
            solicitud.SeguridadUsuarioId = userId;
            solicitud.FechaRespuesta = DateTime.UtcNow;

            // Notificar al profesor que alguien va en camino
            if (solicitud.Profesor != null)
            {
                _context.Notificaciones.Add(new Notificacion
                {
                    UsuarioId = solicitud.Profesor.UsuarioId ?? 0,
                    Titulo = "🏃 Seguridad en camino",
                    Cuerpo = $"Un oficial de seguridad va en camino a abrir {solicitud.Aula?.Nombre ?? "el aula"}.",
                    Tipo = "AperturaEnCamino",
                    Leida = false,
                    FechaCreacion = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Marcado como 'En Camino'. El profesor ha sido notificado.", solicitud.Estado });
        }

        /// <summary>
        /// Seguridad confirma que el aula ha sido abierta.
        /// Actualiza el estado del aula a "Ocupada" y asigna el profesor.
        /// </summary>
        [HttpPut("solicitudes/{id}/completar")]
        public async Task<IActionResult> CompletarApertura(int id)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var solicitud = await _context.SolicitudesApertura
                .Include(s => s.Aula)
                .Include(s => s.Profesor)
                .FirstOrDefaultAsync(s => s.IdSolicitud == id);

            if (solicitud == null) return NotFound();
            if (solicitud.Estado != "EnCamino" && solicitud.Estado != "Pendiente")
                return BadRequest(new { message = $"No se puede completar una solicitud en estado '{solicitud.Estado}'." });

            solicitud.Estado = "Completada";
            solicitud.SeguridadUsuarioId ??= userId;
            solicitud.FechaCompletada = DateTime.UtcNow;

            // Actualizar estado del aula
            if (solicitud.Aula != null)
            {
                solicitud.Aula.Estado = "Ocupada";
                solicitud.Aula.ProfesorActualId = solicitud.ProfesorId;
                solicitud.Aula.HoraApertura = DateTime.UtcNow;
            }

            // Notificar al profesor
            if (solicitud.Profesor != null)
            {
                _context.Notificaciones.Add(new Notificacion
                {
                    UsuarioId = solicitud.Profesor.UsuarioId ?? 0,
                    Titulo = "✅ Aula abierta",
                    Cuerpo = $"{solicitud.Aula?.Nombre ?? "El aula"} ha sido abierta. Puede ingresar.",
                    Tipo = "AperturaCompletada",
                    Leida = false,
                    FechaCreacion = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Aula abierta exitosamente.", solicitud.Estado });
        }

        /// <summary>
        /// Liberar un aula: marcarla como "Disponible" y quitar al profesor.
        /// Puede hacerlo el profesor o seguridad.
        /// </summary>
        [HttpPut("{aulaId}/liberar")]
        public async Task<IActionResult> LiberarAula(int aulaId)
        {
            var aula = await _context.Aulas.FindAsync(aulaId);
            if (aula == null) return NotFound("Aula no encontrada.");

            aula.Estado = "Disponible";
            aula.ProfesorActualId = null;
            aula.HoraApertura = null;

            await _context.SaveChangesAsync();

            return Ok(new { message = $"{aula.Nombre} liberada.", estado = aula.Estado });
        }

        /// <summary>
        /// Listar solicitudes de apertura (para seguridad: las activas; para profesor: las propias).
        /// </summary>
        [HttpGet("solicitudes")]
        public async Task<IActionResult> GetSolicitudes(
            [FromQuery] string? estado,
            [FromQuery] bool soloMias = false)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var query = _context.SolicitudesApertura
                .Include(s => s.Aula)
                .Include(s => s.Profesor)
                .AsQueryable();

            if (soloMias)
            {
                var profesor = await _context.Profesores
                    .FirstOrDefaultAsync(p => p.UsuarioId == userId);
                if (profesor != null)
                    query = query.Where(s => s.ProfesorId == profesor.IdProfesor);
            }

            if (!string.IsNullOrEmpty(estado))
                query = query.Where(s => s.Estado == estado);

            var solicitudes = await query
                .OrderByDescending(s => s.FechaSolicitud)
                .Select(s => new
                {
                    s.IdSolicitud,
                    aula = s.Aula != null ? s.Aula.Nombre : "N/A",
                    aulaId = s.AulaId,
                    profesor = s.Profesor != null ? $"{s.Profesor.Nombres} {s.Profesor.Apellidos}" : "N/A",
                    s.Estado,
                    s.Motivo,
                    s.FechaSolicitud,
                    s.FechaRespuesta,
                    s.FechaCompletada
                })
                .ToListAsync();

            return Ok(solicitudes);
        }

        // ═══════════════════════════════════════════════════
        // Helpers
        // ═══════════════════════════════════════════════════

        private int? GetUserId()
        {
            var str = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(str, out var id)) return id;
            return null;
        }
    }

    // ═══════════════════════════════════════════════════
    // DTOs
    // ═══════════════════════════════════════════════════

    public class AulaCreateDto
    {
        public string Nombre { get; set; } = string.Empty;
        public string? Edificio { get; set; }
        public string? Piso { get; set; }
    }

    public class SolicitudAperturaDto
    {
        public int AulaId { get; set; }
        public string? Motivo { get; set; }
    }
}
