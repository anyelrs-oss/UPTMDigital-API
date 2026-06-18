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

            // 1. Verify if Cedula belongs to a Student, Professor or Coordinator
            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula == dto.Cedula);
            var profesor = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == dto.Cedula);
            var coordinador = await _context.Coordinadores.FirstOrDefaultAsync(c => c.Usuario != null && c.Usuario.Cedula == dto.Cedula);

            // If not found in specific profiles, check directly in Usuarios (for Security, Secretariat, etc.)
            var usuario = await _context.Usuarios.Include(u => u.Rol).FirstOrDefaultAsync(u => u.Cedula == dto.Cedula);

            if (usuario == null && estudiante == null && profesor == null)
            {
                return NotFound("Cédula no encontrada en el sistema.");
            }

            // 2. Identify the person
            string nombre = "Usuario";
            string rol = "N/A";

            if (estudiante != null) {
                nombre = $"{estudiante.Nombres} {estudiante.Apellidos}";
                rol = "Estudiante";
            } else if (profesor != null) {
                nombre = $"{profesor.Nombres} {profesor.Apellidos}";
                rol = "Profesor";
            } else if (coordinador != null) {
                nombre = $"{coordinador.Nombres} {coordinador.Apellidos}";
                rol = "Coordinador";
            } else if (usuario != null) {
                nombre = usuario.NombreUsuario;
                rol = usuario.Rol?.NombreRol ?? "Personal";
            }

            // 3. Create Access Record
            var registro = new ControlAcceso
            {
                Cedula = dto.Cedula,
                Tipo = dto.Tipo,
                Ubicacion = dto.Ubicacion,
                FechaHora = DateTime.UtcNow,
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
                FechaHora = DateTime.UtcNow
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

        [HttpGet("historial")]
        public async Task<IActionResult> GetHistorialGlobal([FromQuery] int limit = 50)
        {
            var historial = await _context.ControlAccesos
                .OrderByDescending(c => c.FechaHora)
                .Take(limit)
                .ToListAsync();

            // Enriquecer con nombres (Opcional si quieres evitar N+1, mejor usar un Join)
            var cedulas = historial.Select(h => h.Cedula).Distinct().ToList();
            var estudiantes = await _context.Estudiantes.Where(e => cedulas.Contains(e.Cedula)).ToDictionaryAsync(e => e.Cedula, e => $"{e.Nombres} {e.Apellidos}");
            var profesores = await _context.Profesores.Where(p => cedulas.Contains(p.Cedula)).ToDictionaryAsync(p => p.Cedula, p => $"{p.Nombres} {p.Apellidos}");

            var resultado = historial.Select(h => new {
                h.Id,
                h.Cedula,
                h.Tipo,
                h.Ubicacion,
                h.FechaHora,
                Nombre = estudiantes.ContainsKey(h.Cedula) ? estudiantes[h.Cedula] : (profesores.ContainsKey(h.Cedula) ? profesores[h.Cedula] : "Visitante/Otro"),
                Rol = estudiantes.ContainsKey(h.Cedula) ? "Estudiante" : (profesores.ContainsKey(h.Cedula) ? "Profesor" : "N/A")
            });

            return Ok(resultado);
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
