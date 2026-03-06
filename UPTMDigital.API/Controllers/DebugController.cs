using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DebugController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public DebugController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet("users")]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _context.Usuarios.Select(u => new 
            {
                u.IdUsuario,
                u.NombreUsuario,
                u.ContrasenaHash,
                Role = u.Rol.NombreRol
            }).ToListAsync();

            return Ok(users);
        }
    }
}
