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

        // GET: api/profesores
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Profesor>>> GetProfesores()
        {
            return await _context.Profesores.ToListAsync();
        }

        // GET: api/profesores/me
        [HttpGet("me")]
        public async Task<ActionResult<Profesor>> GetMe()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            if (string.IsNullOrEmpty(username)) return Unauthorized();

            Profesor? profesor;
            try
            {
                profesor = await _context.Profesores
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.UsuarioLogin == username);
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

        // DELETE: api/profesores/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProfesor(int id)
        {
            var profesor = await _context.Profesores.FindAsync(id);
            if (profesor == null)
            {
                return NotFound();
            }

            _context.Profesores.Remove(profesor);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool ProfesorExists(int id)
        {
            return _context.Profesores.Any(e => e.IdProfesor == id);
        }
    }
}
