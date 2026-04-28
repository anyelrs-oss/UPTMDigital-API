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
    public class ProfesoresController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public ProfesoresController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // GET: api/profesores?search=&departamento=&activo=
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Profesor>>> GetProfesores(
            [FromQuery] string? search,
            [FromQuery] string? departamento,
            [FromQuery] bool? activo)
        {
            var query = _context.Profesores.AsQueryable();

            if (activo.HasValue)
                query = query.Where(p => p.Activo == activo.Value);
            else
                query = query.Where(p => p.Activo);

            if (!string.IsNullOrEmpty(search))
            {
                var s = search.ToLower();
                query = query.Where(p =>
                    p.Nombres.ToLower().Contains(s) ||
                    p.Apellidos.ToLower().Contains(s) ||
                    p.Cedula.ToLower().Contains(s));
            }

            if (!string.IsNullOrEmpty(departamento))
                query = query.Where(p => p.Departamento != null && p.Departamento.ToLower().Contains(departamento.ToLower()));

            return await query.OrderBy(p => p.Apellidos).ToListAsync();
        }

        // GET: api/profesores/me
        [HttpGet("me")]
        public async Task<ActionResult<Profesor>> GetMe()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            Profesor? profesor;
            try
            {
                profesor = await _context.Profesores
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.UsuarioId == userId);
            }
            catch (Exception ex) when (IsTransientDbException(ex))
            {
                return StatusCode(503, new
                {
                    message = "Servicio temporalmente no disponible al cargar perfil. Intente de nuevo en unos segundos."
                });
            }

            if (profesor == null) return NotFound("Profesor profile not linked to this user.");

            return profesor;
        }

        /// <summary>
        /// Asignaturas que dicta el profesor autenticado.
        /// </summary>
        [HttpGet("me/asignaturas")]
        public async Task<IActionResult> GetMisAsignaturas()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var profesor = await _context.Profesores
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.UsuarioId == userId);

            if (profesor == null) return NotFound();

            var asignaturas = await _context.Asignaturas
                .AsNoTracking()
                .Where(a => a.ProfesorId == profesor.IdProfesor)
                .Select(a => new
                {
                    a.IdAsignatura,
                    a.Codigo,
                    a.Nombre,
                    a.Creditos,
                    a.Semestre,
                    a.Departamento
                })
                .ToListAsync();

            return Ok(asignaturas);
        }

        /// <summary>
        /// Horario de todas las asignaturas del profesor autenticado.
        /// </summary>
        [HttpGet("me/horario")]
        public async Task<IActionResult> GetMiHorario()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId)) return Unauthorized();

            var profesor = await _context.Profesores
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.UsuarioId == userId);

            if (profesor == null) return NotFound();

            var asignaturaIds = await _context.Asignaturas
                .AsNoTracking()
                .Where(a => a.ProfesorId == profesor.IdProfesor)
                .Select(a => a.IdAsignatura)
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

        // GET: api/profesores/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Profesor>> GetProfesor(int id)
        {
            var profesor = await _context.Profesores.FindAsync(id);

            if (profesor == null)
            {
                return NotFound();
            }

            return profesor;
        }

        // POST: api/profesores
        [HttpPost]
        public async Task<ActionResult<Profesor>> PostProfesor(Profesor profesor)
        {
            _context.Profesores.Add(profesor);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetProfesor), new { id = profesor.IdProfesor }, profesor);
        }

        // PUT: api/profesores/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutProfesor(int id, Profesor profesor)
        {
            if (id != profesor.IdProfesor)
            {
                return BadRequest();
            }

            _context.Entry(profesor).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ProfesorExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // DELETE: api/profesores/5 (soft delete)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProfesor(int id)
        {
            var profesor = await _context.Profesores.FindAsync(id);
            if (profesor == null) return NotFound();

            profesor.Activo = false;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Profesor desactivado." });
        }

        private bool ProfesorExists(int id)
        {
            return _context.Profesores.Any(e => e.IdProfesor == id);
        }
    }
}
