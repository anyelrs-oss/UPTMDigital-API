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
    public class SettingsController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public SettingsController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet("{clave}")]
        public async Task<IActionResult> GetSetting(string clave)
        {
            var setting = await _context.GlobalSettings.FindAsync(clave);
            if (setting == null) return NotFound();
            return Ok(setting);
        }

        [Authorize]
        [HttpPost]
        public async Task<IActionResult> SetSetting([FromBody] GlobalSetting setting)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

            if (userRole != "Administrador")
            {
                if (userRole == "Profesor" && setting.Clave.StartsWith("Confirmado_Asignatura_"))
                {
                    var parts = setting.Clave.Split('_');
                    if (parts.Length == 3 && int.TryParse(parts[2], out int asigId))
                    {
                        if (int.TryParse(userIdStr, out var userId))
                        {
                            var prof = await _context.Profesores.FirstOrDefaultAsync(p => p.UsuarioId == userId);
                            var asig = await _context.Asignaturas.FindAsync(asigId);
                            if (prof == null || asig == null || asig.ProfesorId != prof.IdProfesor)
                            {
                                return Forbid();
                            }
                        }
                        else
                        {
                            return Unauthorized();
                        }
                    }
                    else
                    {
                        return BadRequest("Formato de clave inválido.");
                    }
                }
                else
                {
                    return Forbid();
                }
            }

            var existing = await _context.GlobalSettings.FindAsync(setting.Clave);
            if (existing == null)
            {
                _context.GlobalSettings.Add(setting);
            }
            else
            {
                existing.Valor = setting.Valor;
                existing.UltimaActualizacion = DateTime.UtcNow;
            }
            await _context.SaveChangesAsync();
            return Ok(setting);
        }
    }
}
