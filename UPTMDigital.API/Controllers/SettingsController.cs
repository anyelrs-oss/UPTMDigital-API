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

        [Authorize(Roles = "Administrador")]
        [HttpPost]
        public async Task<IActionResult> SetSetting([FromBody] GlobalSetting setting)
        {
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
