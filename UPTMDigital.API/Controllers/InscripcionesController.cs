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
    public class InscripcionesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public InscripcionesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Inscripcion>>> GetInscripciones()
        {
            return await _context.Inscripciones
                .Include(i => i.Estudiante)
                .Include(i => i.Asignatura)
                .ToListAsync();
        }

        [HttpGet("asignatura/{asignaturaId}")]
        public async Task<ActionResult<IEnumerable<Inscripcion>>> GetInscripcionesByAsignatura(int asignaturaId)
        {
            return await _context.Inscripciones
                .Include(i => i.Estudiante)
                .Where(i => i.AsignaturaId == asignaturaId)
                .ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Inscripcion>> GetInscripcion(int id)
        {
            var inscripcion = await _context.Inscripciones
                .Include(i => i.Estudiante)
                .Include(i => i.Asignatura)
                .FirstOrDefaultAsync(i => i.IdInscripcion == id);

            if (inscripcion == null) return NotFound();
            return inscripcion;
        }

        [HttpPost]
        public async Task<ActionResult<Inscripcion>> PostInscripcion(Inscripcion inscripcion)
        {
            _context.Inscripciones.Add(inscripcion);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetInscripcion), new { id = inscripcion.IdInscripcion }, inscripcion);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutInscripcion(int id, Inscripcion inscripcion)
        {
            if (id != inscripcion.IdInscripcion) return BadRequest();
            _context.Entry(inscripcion).State = EntityState.Modified;
            try { await _context.SaveChangesAsync(); }
            catch (DbUpdateConcurrencyException) { if (!InscripcionExists(id)) return NotFound(); else throw; }
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteInscripcion(int id)
        {
            var inscripcion = await _context.Inscripciones.FindAsync(id);
            if (inscripcion == null) return NotFound();
            _context.Inscripciones.Remove(inscripcion);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        private bool InscripcionExists(int id) => _context.Inscripciones.Any(e => e.IdInscripcion == id);
    }
}
