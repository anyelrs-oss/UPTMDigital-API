using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.DTOs;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ControlAccesoController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public ControlAccesoController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpPost("registrar")]
        public async Task<IActionResult> RegistrarAcceso([FromBody] ControlAccesoDto dto)
        {
            if (string.IsNullOrEmpty(dto.Cedula))
            {
                return BadRequest("La Cédula es obligatoria.");
            }

            // 1. Verify if Cedula belongs to a Student or Professor
            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula == dto.Cedula);
            var profesor = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == dto.Cedula);

            if (estudiante == null && profesor == null)
            {
                return NotFound("Cédula no encontrada en el sistema.");
            }

            // 2. Identify the person
            string nombre = estudiante != null ? $"{estudiante.Nombres} {estudiante.Apellidos}" : $"{profesor!.Nombres} {profesor.Apellidos}";
            string rol = estudiante != null ? "Estudiante" : "Profesor";

            // 3. Create Access Record
            var registro = new ControlAcceso
            {
                Cedula = dto.Cedula,
                Tipo = dto.Tipo,
                Ubicacion = dto.Ubicacion,
                FechaHora = DateTime.Now,
                // PersonalSeguridadId could be taken from User.Claims if Auth is implemented
            };

            _context.ControlAccesos.Add(registro);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Mensaje = "Acceso Registrado Exitosamente",
                Nombre = nombre,
                Rol = rol,
                Tipo = dto.Tipo,
                Fecha = registro.FechaHora
            });
        }

        [HttpPost("apertura")]
        public async Task<IActionResult> RegistrarApertura([FromBody] ControlAccesoDto dto)
        {
            if (string.IsNullOrEmpty(dto.Cedula) || string.IsNullOrEmpty(dto.Ubicacion))
            {
                return BadRequest("Cédula y Ubicación (Aula) son obligatorios.");
            }

            // Verify if Cedula belongs to a Professor
            var profesor = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == dto.Cedula);

            if (profesor == null)
            {
                return Unauthorized("Solo los profesores autorizados pueden abrir aulas.");
            }

            var registro = new ControlAcceso
            {
                Cedula = dto.Cedula,
                Tipo = "Apertura",
                Ubicacion = dto.Ubicacion, // The specific room
                FechaHora = DateTime.Now
            };

            _context.ControlAccesos.Add(registro);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Mensaje = $"Aula {dto.Ubicacion} abierta exitosamente por {profesor.Nombres} {profesor.Apellidos}",
                Profesor = $"{profesor.Nombres} {profesor.Apellidos}",
                Aula = dto.Ubicacion,
                Fecha = registro.FechaHora
            });
        }

        [HttpGet("historial/{cedula}")]
        public async Task<IActionResult> GetHistorial(string cedula)
        {
             var historial = await _context.ControlAccesos
                .Where(c => c.Cedula == cedula)
                .OrderByDescending(c => c.FechaHora)
                .Take(20)
                .ToListAsync();

            return Ok(historial);
        }
    }
}
