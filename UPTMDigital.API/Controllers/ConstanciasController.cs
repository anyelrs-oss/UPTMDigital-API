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
    public class ConstanciasController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public ConstanciasController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Constancia>>> GetConstancias()
        {
            return await _context.Constancias
                .Include(c => c.Estudiante)
                .ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Constancia>> GetConstancia(int id)
        {
            var constancia = await _context.Constancias.FindAsync(id);
            if (constancia == null) return NotFound();
            return constancia;
        }

        [HttpPost]
        public async Task<ActionResult<Constancia>> PostConstancia(Constancia constancia)
        {
            _context.Constancias.Add(constancia);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetConstancia), new { id = constancia.IdConstancia }, constancia);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutConstancia(int id, Constancia constancia)
        {
            if (id != constancia.IdConstancia) return BadRequest();
            _context.Entry(constancia).State = EntityState.Modified;
            try { await _context.SaveChangesAsync(); }
            catch (DbUpdateConcurrencyException) { if (!ConstanciaExists(id)) return NotFound(); else throw; }
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteConstancia(int id)
        {
            var constancia = await _context.Constancias.FindAsync(id);
            if (constancia == null) return NotFound();
            _context.Constancias.Remove(constancia);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        private bool ConstanciaExists(int id) => _context.Constancias.Any(e => e.IdConstancia == id);
    }
}
