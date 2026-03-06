using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HorariosController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public HorariosController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // GET: api/Horarios/asignatura/5
        [HttpGet("asignatura/{asignaturaId}")]
        public async Task<ActionResult<IEnumerable<Horario>>> GetHorariosByAsignatura(int asignaturaId)
        {
            return await _context.Horarios
                .Where(h => h.AsignaturaId == asignaturaId)
                .ToListAsync();
        }

        // POST: api/Horarios
        [HttpPost]
        public async Task<ActionResult<Horario>> PostHorario(Horario horario)
        {
            _context.Horarios.Add(horario);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetHorariosByAsignatura), new { asignaturaId = horario.AsignaturaId }, horario);
        }

        // DELETE: api/Horarios/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteHorario(int id)
        {
            var horario = await _context.Horarios.FindAsync(id);
            if (horario == null)
            {
                return NotFound();
            }

            _context.Horarios.Remove(horario);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
