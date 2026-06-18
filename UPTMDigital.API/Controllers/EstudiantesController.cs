using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;
using System.Security.Claims;

namespace UPTMDigital.API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class EstudiantesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public EstudiantesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // GET: api/estudiantes?search=&carrera=&activo=
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Estudiante>>> GetEstudiantes(
            [FromQuery] string? search,
            [FromQuery] string? carrera,
            [FromQuery] bool? activo,
            [FromQuery] int page = 1,
            [FromQuery] int limit = 50)
        {
            var query = _context.Estudiantes.AsQueryable();

            // Soft delete filter (default: only active)
            if (activo.HasValue)
                query = query.Where(e => e.Activo == activo.Value);
            else
                query = query.Where(e => e.Activo);

            if (!string.IsNullOrEmpty(search))
            {
                // Use EF.Functions.ILike for case-insensitive search (more efficient with indexes)
                var pattern = $"%{search}%";
                query = query.Where(e =>
                    EF.Functions.ILike(e.Nombres, pattern) ||
                    EF.Functions.ILike(e.Apellidos, pattern) ||
                    EF.Functions.ILike(e.Cedula, pattern));
            }

            if (!string.IsNullOrEmpty(carrera))
                query = query.Where(e => e.Carrera != null && e.Carrera.Nombre.ToLower().Contains(carrera.ToLower()));

            // Paginación segura
            if (limit > 100) limit = 100;
            if (page < 1) page = 1;
            var skip = (page - 1) * limit;

            var total = await query.CountAsync();
            var items = await query.OrderBy(e => e.Apellidos)
                .Skip(skip)
                .Take(limit)
                .ToListAsync();

            Response.Headers.Add("X-Total-Count", total.ToString());
            return items;
        }

        // GET: api/estudiantes/me
        [HttpGet("me")]
        public async Task<ActionResult<Estudiante>> GetMe()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            Estudiante? estudiante;
            try
            {
                estudiante = await _context.Estudiantes
                    .AsNoTracking()
                    .FirstOrDefaultAsync(e => e.UsuarioId == userId);
            }
            catch (Exception ex) when (IsTransientDbException(ex))
            {
                return StatusCode(503, new
                {
                    message = "Servicio temporalmente no disponible al cargar perfil. Intente de nuevo en unos segundos."
                });
            }

            if (estudiante == null) return NotFound("Student profile not linked to this user.");

            return estudiante;
        }

        /// <summary>
        /// Notas del estudiante autenticado, enriquecidas con nombre de asignatura.
        /// El frontend puede mostrar directamente: "Algoritmos y Programación I — 18 pts".
        /// </summary>
        [HttpGet("me/notas")]
        public async Task<IActionResult> GetMisNotas()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var estudiante = await _context.Estudiantes
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.UsuarioId == userId);

            if (estudiante == null) return NotFound("Perfil de estudiante no vinculado.");

            var notas = await _context.Notas
                .AsNoTracking()
                .Include(n => n.Asignatura)
                .Include(n => n.Profesor)
                .Where(n => n.EstudianteId == estudiante.IdEstudiante)
                .OrderByDescending(n => n.Fecha)
                .Select(n => new
                {
                    n.IdNota,
                    n.Calificacion,
                    n.Fecha,
                    n.CodigoQR,
                    asignatura = n.Asignatura != null ? n.Asignatura.Nombre : "N/A",
                    asignaturaNombre = n.Asignatura != null ? n.Asignatura.Nombre : "N/A",
                    codigoAsignatura = n.Asignatura != null ? n.Asignatura.Codigo : "N/A",
                    profesorNombre = n.Profesor != null ? n.Profesor.Nombres + " " + n.Profesor.Apellidos : "N/A"
                })
                .ToListAsync();

            return Ok(notas);
        }

        /// <summary>
        /// Asistencias del estudiante autenticado con nombre de asignatura.
        /// </summary>
        [HttpGet("me/asistencias")]
        public async Task<IActionResult> GetMisAsistencias()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var estudiante = await _context.Estudiantes
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.UsuarioId == userId);

            if (estudiante == null) return NotFound();

            var asistencias = await _context.Asistencias
                .AsNoTracking()
                .Include(a => a.Asignatura)
                .Where(a => a.EstudianteId == estudiante.IdEstudiante)
                .OrderByDescending(a => a.Fecha)
                .Select(a => new
                {
                    a.IdAsistencia,
                    a.Fecha,
                    a.Estado,
                    asignatura = a.Asignatura != null ? a.Asignatura.Nombre : "N/A"
                })
                .ToListAsync();

            return Ok(asistencias);
        }

        /// <summary>
        /// Horario del estudiante: todas las asignaturas inscritas con sus bloques horarios.
        /// Perfeecto para la pantalla "Mi Horario".
        /// </summary>
        [HttpGet("me/horario")]
        public async Task<IActionResult> GetMiHorario()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var estudiante = await _context.Estudiantes
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.UsuarioId == userId);

            if (estudiante == null) return NotFound();

            // IDs de asignaturas en las que está inscrito
            var asignaturaIds = await _context.Inscripciones
                .AsNoTracking()
                .Where(i => i.EstudianteId == estudiante.IdEstudiante)
                .Select(i => i.AsignaturaId)
                .ToListAsync();

            var horarios = await _context.Horarios
                .AsNoTracking()
                .Include(h => h.Asignatura)
                .Where(h => asignaturaIds.Contains(h.AsignaturaId))
                .OrderBy(h => h.Dia)
                .ThenBy(h => h.HoraInicio)
                .Select(h => new
                {
                    h.IdHorario,
                    h.Dia,
                    h.HoraInicio,
                    h.HoraFin,
                    h.Aula,
                    asignatura = h.Asignatura != null ? h.Asignatura.Nombre : "N/A",
                    codigo = h.Asignatura != null ? h.Asignatura.Codigo : "N/A"
                })
                .ToListAsync();

            return Ok(horarios);
        }

        /// <summary>
        /// Asignaturas en las que está inscrito el estudiante, con detalles de la asignatura.
        /// </summary>
        [HttpGet("me/inscripciones")]
        public async Task<IActionResult> GetMisInscripciones()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var estudiante = await _context.Estudiantes
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.UsuarioId == userId);

            if (estudiante == null) return NotFound();

            var inscripciones = await _context.Inscripciones
                .AsNoTracking()
                .Include(i => i.Asignatura)
                .Where(i => i.EstudianteId == estudiante.IdEstudiante)
                .Select(i => new
                {
                    i.IdInscripcion,
                    i.Periodo,
                    i.Estado,
                    i.FechaInscripcion,
                    asignaturaId = i.AsignaturaId,
                    asignatura = i.Asignatura != null ? i.Asignatura.Nombre : "N/A",
                    codigo = i.Asignatura != null ? i.Asignatura.Codigo : "N/A",
                    creditos = i.Asignatura != null ? i.Asignatura.Creditos : 0
                })
                .ToListAsync();

            return Ok(inscripciones);
        }

        private static bool IsTransientDbException(Exception ex)
        {
            if (ex is TimeoutException || ex is NpgsqlException)
            {
                return true;
            }

            if (ex is InvalidOperationException && ex.InnerException is NpgsqlException)
            {
                return true;
            }

            return ex.InnerException is TimeoutException || ex.InnerException is NpgsqlException;
        }

        // GET: api/estudiantes/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Estudiante>> GetEstudiante(int id)
        {
            var estudiante = await _context.Estudiantes.FindAsync(id);
            if (estudiante == null) return NotFound();
            return estudiante;
        }

        // POST: api/estudiantes
        [HttpPost]
        public async Task<ActionResult<Estudiante>> PostEstudiante(Estudiante estudiante)
        {
            _context.Estudiantes.Add(estudiante);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetEstudiante), new { id = estudiante.IdEstudiante }, estudiante);
        }

        // PUT: api/estudiantes/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutEstudiante(int id, Estudiante estudiante)
        {
            if (id != estudiante.IdEstudiante) return BadRequest();

            _context.Entry(estudiante).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!_context.Estudiantes.Any(e => e.IdEstudiante == id))
                    return NotFound();
                throw;
            }
            return NoContent();
        }

        // DELETE: api/estudiantes/5 (soft delete)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteEstudiante(int id)
        {
            var estudiante = await _context.Estudiantes.FindAsync(id);
            if (estudiante == null) return NotFound();

            estudiante.Activo = false;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Estudiante desactivado." });
        }
    }
}