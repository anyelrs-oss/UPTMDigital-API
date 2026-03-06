using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminDataController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public AdminDataController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // --- Carreras ---
        [HttpGet("carreras")]
        public async Task<ActionResult<IEnumerable<Carrera>>> GetCarreras()
        {
            return await _context.Carreras.ToListAsync();
        }

        [HttpPost("carreras")]
        public async Task<ActionResult<Carrera>> PostCarrera(Carrera carrera)
        {
            _context.Carreras.Add(carrera);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetCarreras", new { id = carrera.IdCarrera }, carrera);
        }

        [HttpDelete("carreras/{id}")]
        public async Task<IActionResult> DeleteCarrera(int id)
        {
            var carrera = await _context.Carreras.FindAsync(id);
            if (carrera == null) return NotFound();
            
            _context.Carreras.Remove(carrera);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // --- Semestres ---
        [HttpGet("semestres")]
        public async Task<ActionResult<IEnumerable<Semestre>>> GetSemestres()
        {
            return await _context.Semestres.ToListAsync();
        }

        [HttpPost("semestres")]
        public async Task<ActionResult<Semestre>> PostSemestre(Semestre semestre)
        {
            _context.Semestres.Add(semestre);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetSemestres", new { id = semestre.IdSemestre }, semestre);
        }

        [HttpDelete("semestres/{id}")]
        public async Task<IActionResult> DeleteSemestre(int id)
        {
            var item = await _context.Semestres.FindAsync(id);
            if (item == null) return NotFound();
            _context.Semestres.Remove(item);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // --- Periodos ---
        [HttpGet("periodos")]
        public async Task<ActionResult<IEnumerable<Periodo>>> GetPeriodos()
        {
            return await _context.Periodos.ToListAsync();
        }

        [HttpPost("periodos")]
        public async Task<ActionResult<Periodo>> PostPeriodo(Periodo periodo)
        {
            _context.Periodos.Add(periodo);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetPeriodos", new { id = periodo.IdPeriodo }, periodo);
        }
        
        [HttpDelete("periodos/{id}")]
        public async Task<IActionResult> DeletePeriodo(int id)
        {
            var item = await _context.Periodos.FindAsync(id);
            if (item == null) return NotFound();
            _context.Periodos.Remove(item);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
