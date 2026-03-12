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

        // GET: api/estudiantes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Estudiante>>> GetEstudiantes()
        {
            return await _context.Estudiantes.ToListAsync();
        }

        // GET: api/estudiantes/me
        [HttpGet("me")]
        public async Task<ActionResult<Estudiante>> GetMe()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            if (string.IsNullOrEmpty(username)) return Unauthorized();

            Estudiante? estudiante;
            try
            {
                estudiante = await _context.Estudiantes
                    .AsNoTracking()
                    .FirstOrDefaultAsync(e => e.UsuarioLogin == username);
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

        // DELETE: api/estudiantes/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteEstudiante(int id)
        {
            var estudiante = await _context.Estudiantes.FindAsync(id);
            if (estudiante == null) return NotFound();

            _context.Estudiantes.Remove(estudiante);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}