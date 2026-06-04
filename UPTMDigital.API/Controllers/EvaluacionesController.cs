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
    public class EvaluacionesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public EvaluacionesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet("asignatura/{asignaturaId}")]
        public async Task<ActionResult<IEnumerable<EvaluacionConfig>>> GetEvaluaciones(int asignaturaId)
        {
            return await _context.EvaluacionesConfig
                .Where(e => e.AsignaturaId == asignaturaId && e.Activo)
                .OrderBy(e => e.FechaEvaluacion)
                .ToListAsync();
        }

        [HttpPost]
        public async Task<ActionResult<EvaluacionConfig>> PostEvaluacion(EvaluacionConfig config)
        {
            _context.EvaluacionesConfig.Add(config);
            await _context.SaveChangesAsync();
            return Ok(config);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteEvaluacion(int id)
        {
            var config = await _context.EvaluacionesConfig.FindAsync(id);
            if (config == null) return NotFound();
            config.Activo = false;
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
