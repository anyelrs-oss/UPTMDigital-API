using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class AsignaturasController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public AsignaturasController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // GET: api/asignaturas?search=&departamento=&profesorId=&activo=
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Asignatura>>> GetAsignaturas(
            [FromQuery] string? search,
            [FromQuery] string? departamento,
            [FromQuery] int? profesorId,
            [FromQuery] bool? activo)
        {
            var query = _context.Asignaturas.Include(a => a.Profesor).AsQueryable();

            if (activo.HasValue)
                query = query.Where(a => a.Activo == activo.Value);
            else
                query = query.Where(a => a.Activo);

            if (!string.IsNullOrEmpty(search))
            {
                var s = search.ToLower();
                query = query.Where(a =>
                    a.Nombre.ToLower().Contains(s) ||
                    a.Codigo.ToLower().Contains(s));
            }

            if (!string.IsNullOrEmpty(departamento))
                query = query.Where(a => a.Departamento != null && a.Departamento.ToLower().Contains(departamento.ToLower()));

            if (profesorId.HasValue)
                query = query.Where(a => a.ProfesorId == profesorId.Value);

            return await query.OrderBy(a => a.Nombre).ToListAsync();
        }

        // GET: api/asignaturas/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Asignatura>> GetAsignatura(int id)
        {
            var asignatura = await _context.Asignaturas.FindAsync(id);

            if (asignatura == null)
            {
                return NotFound();
            }

            return asignatura;
        }

        // POST: api/asignaturas
        [HttpPost]
        public async Task<ActionResult<Asignatura>> PostAsignatura(Asignatura asignatura)
        {
            _context.Asignaturas.Add(asignatura);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetAsignatura), new { id = asignatura.IdAsignatura }, asignatura);
        }

        // PUT: api/asignaturas/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutAsignatura(int id, Asignatura asignatura)
        {
            if (id != asignatura.IdAsignatura)
            {
                return BadRequest();
            }

            _context.Entry(asignatura).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!AsignaturaExists(id))
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

        // DELETE: api/asignaturas/5 (soft delete)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAsignatura(int id)
        {
            var asignatura = await _context.Asignaturas.FindAsync(id);
            if (asignatura == null) return NotFound();

            asignatura.Activo = false;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Asignatura desactivada." });
        }

        private bool AsignaturaExists(int id)
        {
            return _context.Asignaturas.Any(e => e.IdAsignatura == id);
        }
    }
}
