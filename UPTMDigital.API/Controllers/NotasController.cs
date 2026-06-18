using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
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
        public async Task<IActionResult> GetNotas([FromQuery] string? search, [FromQuery] int? asignaturaId, [FromQuery] int? estudianteId)
        {
            var query = _context.Notas
                .Include(n => n.Estudiante)
                .Include(n => n.Asignatura)
                .AsQueryable();

            if (asignaturaId.HasValue)
                query = query.Where(n => n.AsignaturaId == asignaturaId.Value);

            if (estudianteId.HasValue)
                query = query.Where(n => n.EstudianteId == estudianteId.Value);

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

        [HttpPost("masivo")]
        public async Task<IActionResult> PostNotasMasivo([FromBody] NotasMasivasDto dto)
        {
            if (dto.EvaluacionId <= 0) return BadRequest("ID de evaluación inválido.");
            if (dto.Notas == null || !dto.Notas.Any()) return BadRequest("No se proporcionaron notas.");

            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            int? profesorId = null;
            if (int.TryParse(userIdStr, out var userId))
            {
                var prof = await _context.Profesores.FirstOrDefaultAsync(p => p.UsuarioId == userId);
                profesorId = prof?.IdProfesor;
            }

            foreach (var item in dto.Notas)
            {
                // Buscar si ya existe una nota para este estudiante y esta evaluación para actualizarla
                var notaExistente = await _context.Notas
                    .FirstOrDefaultAsync(n => n.EstudianteId == item.EstudianteId && n.EvaluacionId == dto.EvaluacionId);

                if (notaExistente != null)
                {
                    notaExistente.Calificacion = item.Calificacion;
                    notaExistente.Fecha = DateTime.UtcNow;
                    notaExistente.ProfesorId = profesorId;
                }
                else
                {
                    var nuevaNota = new Nota
                    {
                        AsignaturaId = dto.AsignaturaId,
                        EstudianteId = item.EstudianteId,
                        EvaluacionId = dto.EvaluacionId,
                        Calificacion = item.Calificacion,
                        Fecha = DateTime.UtcNow,
                        ProfesorId = profesorId
                    };
                    _context.Notas.Add(nuevaNota);
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = $"Se procesaron {dto.Notas.Count} notas exitosamente." });
        }

        private bool NotaExists(int id) => _context.Notas.Any(e => e.IdNota == id);
    }

    public class NotasMasivasDto
    {
        public int AsignaturaId { get; set; }
        public int EvaluacionId { get; set; }
        public List<NotaItemDto> Notas { get; set; } = new();
    }

    public class NotaItemDto
    {
        public int EstudianteId { get; set; }
        public decimal Calificacion { get; set; }
    }
}
