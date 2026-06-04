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
    public class NotasController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public NotasController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetNotas([FromQuery] string? search, [FromQuery] int? asignaturaId)
        {
            var query = _context.Notas
                .Include(n => n.Estudiante)
                .Include(n => n.Asignatura)
                .AsQueryable();

            if (asignaturaId.HasValue)
                query = query.Where(n => n.AsignaturaId == asignaturaId.Value);

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(n =>
                    n.Estudiante.Cedula.Contains(search) ||
                    n.Estudiante.Nombres.Contains(search) ||
                    n.Estudiante.Apellidos.Contains(search));
            }

            var notas = await query
                .OrderByDescending(n => n.Fecha)
                .Select(n => new {
                    n.IdNota,
                    n.AsignaturaId,
                    asignaturaNombre = n.Asignatura.Nombre,
                    n.EstudianteId,
                    estudianteNombre = n.Estudiante.Nombres + " " + n.Estudiante.Apellidos,
                    estudianteCedula = n.Estudiante.Cedula,
                    n.Calificacion,
                    n.Fecha
                    // REMOVED: audit query was causing N+1. Access audit logs via separate endpoint if needed.
                })
                .ToListAsync();

            return Ok(notas);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Nota>> GetNota(int id)
        {
            var nota = await _context.Notas.FindAsync(id);
            if (nota == null) return NotFound();
            return nota;
        }

        [HttpPost]
        public async Task<ActionResult<Nota>> PostNota(Nota nota)
        {
            _context.Notas.Add(nota);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetNota), new { id = nota.IdNota }, nota);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutNota(int id, Nota nota)
        {
            if (id != nota.IdNota) return BadRequest();
            _context.Entry(nota).State = EntityState.Modified;
            try { await _context.SaveChangesAsync(); }
            catch (DbUpdateConcurrencyException) { if (!NotaExists(id)) return NotFound(); else throw; }
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNota(int id)
        {
            var nota = await _context.Notas.FindAsync(id);
            if (nota == null) return NotFound();
            _context.Notas.Remove(nota);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        private bool NotaExists(int id) => _context.Notas.Any(e => e.IdNota == id);
    }
}
