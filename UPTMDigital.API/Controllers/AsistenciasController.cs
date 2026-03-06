using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;
using System.Text.Json;

namespace UPTMDigital.API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class AsistenciasController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public AsistenciasController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Asistencia>>> GetAsistencias()
        {
            return await _context.Asistencias
                .Include(a => a.Estudiante)
                .Include(a => a.Asignatura)
                .ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Asistencia>> GetAsistencia(int id)
        {
            var asistencia = await _context.Asistencias.FindAsync(id);
            if (asistencia == null) return NotFound();
            return asistencia;
        }

        [HttpPost]
        public async Task<ActionResult<Asistencia>> PostAsistencia(Asistencia asistencia)
        {
            _context.Asistencias.Add(asistencia);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetAsistencia), new { id = asistencia.IdAsistencia }, asistencia);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutAsistencia(int id, Asistencia asistencia)
        {
            if (id != asistencia.IdAsistencia) return BadRequest();
            _context.Entry(asistencia).State = EntityState.Modified;
            try { await _context.SaveChangesAsync(); }
            catch (DbUpdateConcurrencyException) { if (!AsistenciaExists(id)) return NotFound(); else throw; }
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAsistencia(int id)
        {
            var asistencia = await _context.Asistencias.FindAsync(id);
            if (asistencia == null) return NotFound();
            _context.Asistencias.Remove(asistencia);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        private bool AsistenciaExists(int id) => _context.Asistencias.Any(e => e.IdAsistencia == id);
        // POST: api/Asistencias/qr
        [HttpPost("qr")]
        public async Task<ActionResult> RegistrarAsistenciaQR([FromBody] JsonElement payload)
        {
            // Expected payload: { "estudianteId": 1, "asignaturaId": 2, "timestamp": "..." }
            try 
            {
                int estudianteId = payload.GetProperty("estudianteId").GetInt32();
                int asignaturaId = payload.GetProperty("asignaturaId").GetInt32();
                
                // 1. Validate if student is enrolled (Simple check)
                var inscripcion = await _context.Inscripciones
                    .FirstOrDefaultAsync(i => i.EstudianteId == estudianteId && i.AsignaturaId == asignaturaId);
                
                if (inscripcion == null) return BadRequest("Estudiante no inscrito en esta asignatura.");

                // 2. Check if attendance already exists for today
                var today = DateTime.Today;
                var existe = await _context.Asistencias
                    .AnyAsync(a => a.EstudianteId == estudianteId && a.AsignaturaId == asignaturaId && a.Fecha == today);

                if (existe) return Ok(new { message = "Asistencia ya registrada previamente." });

                // 3. Register Attendance
                var asistencia = new Asistencia
                {
                    EstudianteId = estudianteId,
                    AsignaturaId = asignaturaId,
                    Fecha = today,
                    Estado = "Presente"
                };

                _context.Asistencias.Add(asistencia);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Asistencia registrada exitosamente." });
            }
            catch (Exception ex)
            {
                return BadRequest($"Error procesando QR: {ex.Message}");
            }
        }
    }
}
