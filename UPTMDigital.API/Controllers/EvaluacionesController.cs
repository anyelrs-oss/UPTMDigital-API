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
            if (config.FechaEvaluacion.Kind != DateTimeKind.Utc)
            {
                config.FechaEvaluacion = DateTime.SpecifyKind(config.FechaEvaluacion, DateTimeKind.Utc);
            }
            config.Activo = true;
            _context.EvaluacionesConfig.Add(config);
            await _context.SaveChangesAsync();
            return Ok(config);
        }

        [HttpPost("bulk/{asignaturaId}")]
        public async Task<IActionResult> PostPlan(int asignaturaId, [FromBody] List<EvaluacionConfig> newConfigs)
        {
            var executionStrategy = _context.Database.CreateExecutionStrategy();

            try
            {
                await executionStrategy.ExecuteAsync(async () =>
                {
                    using var transaction = await _context.Database.BeginTransactionAsync();
                    try
                    {
                        // 1. Desactivar las evaluaciones anteriores de esa materia
                        var oldConfigs = await _context.EvaluacionesConfig
                            .Where(e => e.AsignaturaId == asignaturaId && e.Activo)
                            .ToListAsync();

                        foreach (var old in oldConfigs)
                        {
                            old.Activo = false;
                        }

                        // 2. Agregar las nuevas evaluaciones
                        foreach (var config in newConfigs)
                        {
                            config.AsignaturaId = asignaturaId;
                            if (config.FechaEvaluacion.Kind != DateTimeKind.Utc)
                            {
                                config.FechaEvaluacion = DateTime.SpecifyKind(config.FechaEvaluacion, DateTimeKind.Utc);
                            }
                            config.Activo = true;
                            config.IdEvaluacion = 0; // Forzar inserción
                            _context.EvaluacionesConfig.Add(config);
                        }

                        await _context.SaveChangesAsync();
                        await transaction.CommitAsync();
                    }
                    catch
                    {
                        await transaction.RollbackAsync();
                        throw;
                    }
                });

                return Ok(new { message = $"Plan de evaluación guardado. Se agregaron {newConfigs.Count} evaluaciones." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error al guardar el plan de evaluación: {ex.Message}");
            }
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
