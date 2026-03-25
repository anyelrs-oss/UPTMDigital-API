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
        /// Mensajes de una asignatura específica (chat del aula).
        /// Sin autenticación para permitir que cualquier miembro del aula lea.
        /// </summary>
        [HttpGet("{asignaturaId}")]
        public async Task<ActionResult<IEnumerable<Mensaje>>> GetMensajes(int asignaturaId)
        {
            return await _context.Mensajes
                .Where(m => m.AsignaturaId == asignaturaId)
                .OrderBy(m => m.FechaEnvio)
                .ToListAsync();
        }

        /// <summary>
        /// Retorna la lista de chats del usuario autenticado.
        /// Un "chat" = asignatura donde el usuario tiene inscripción o es profesor.
        /// Se usa para la pantalla de lista de conversaciones.
        /// </summary>
        [Authorize]
        [HttpGet("mis-chats")]
        public async Task<IActionResult> GetMisChats()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            var role = User.FindFirst(ClaimTypes.Role)?.Value;

            if (string.IsNullOrEmpty(username)) return Unauthorized();

            List<int> asignaturaIds;

            if (role == "Profesor")
            {
                var profesor = await _context.Profesores
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.UsuarioLogin == username);

                if (profesor == null) return NotFound();

                asignaturaIds = await _context.Asignaturas
                    .AsNoTracking()
                    .Where(a => a.ProfesorId == profesor.IdProfesor)
                    .Select(a => a.IdAsignatura)
                    .ToListAsync();
            }
            else
            {
                var estudiante = await _context.Estudiantes
                    .AsNoTracking()
                    .FirstOrDefaultAsync(e => e.UsuarioLogin == username);

                if (estudiante == null) return NotFound();

                asignaturaIds = await _context.Inscripciones
                    .AsNoTracking()
                    .Where(i => i.EstudianteId == estudiante.IdEstudiante)
                    .Select(i => i.AsignaturaId)
                    .ToListAsync();
            }

            // Para cada asignatura, obtener el último mensaje como preview
            var chats = await _context.Asignaturas
                .AsNoTracking()
                .Where(a => asignaturaIds.Contains(a.IdAsignatura))
                .Select(a => new
                {
                    asignaturaId = a.IdAsignatura,
                    nombre = a.Nombre,
                    codigo = a.Codigo,
                    departamento = a.Departamento,
                    ultimoMensaje = _context.Mensajes
                        .Where(m => m.AsignaturaId == a.IdAsignatura)
                        .OrderByDescending(m => m.FechaEnvio)
                        .Select(m => new
                        {
                            m.Contenido,
                            m.FechaEnvio,
                            m.EmisorNombre
                        })
                        .FirstOrDefault()
                })
                .OrderByDescending(c => c.ultimoMensaje != null ? c.ultimoMensaje.FechaEnvio : DateTime.MinValue)
                .ToListAsync();

            return Ok(chats);
        }

        /// <summary>
        /// Envía un mensaje en el chat de una asignatura.
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<Mensaje>> PostMensaje(Mensaje mensaje)
        {
            mensaje.FechaEnvio = DateTime.UtcNow;
            _context.Mensajes.Add(mensaje);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetMensajes", new { asignaturaId = mensaje.AsignaturaId }, mensaje);
        }
    }
}
