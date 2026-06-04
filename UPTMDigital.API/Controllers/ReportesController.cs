using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Authorize(Roles = "Secretaria,Administrador")]
    [Route("api/[controller]")]
    [ApiController]
    public class ReportesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public ReportesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Obtiene un resumen de asistencia de profesores para reportes administrativos.
        /// </summary>
        [HttpGet("asistencia-docente")]
        public async Task<IActionResult> GetAsistenciaDocente([FromQuery] DateTime? fechaInicio, [FromQuery] DateTime? fechaFin)
        {
            var inicio = fechaInicio ?? DateTime.UtcNow.AddDays(-7);
            var fin = fechaFin ?? DateTime.UtcNow;

            var asistencias = await _context.Asistencias
                .Include(a => a.Profesor)
                .Include(a => a.Asignatura)
                .Where(a => a.Fecha >= inicio && a.Fecha <= fin && a.ProfesorId != null)
                .Select(a => new
                {
                    a.IdAsistencia,
                    fecha = a.Fecha,
                    profesor = a.Profesor != null ? a.Profesor.Nombres + " " + a.Profesor.Apellidos : "N/A",
                    cedula = a.Profesor != null ? a.Profesor.Cedula : "N/A",
                    materia = a.Asignatura.Nombre,
                    estado = a.Estado
                })
                .OrderByDescending(a => a.fecha)
                .ToListAsync();

            return Ok(asistencias);
        }
    }
}
