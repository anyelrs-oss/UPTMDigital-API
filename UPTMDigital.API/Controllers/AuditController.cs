using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Authorize(Roles = "Administrador")] // Solo Admin (o SuperAdmin si decides escalarlo)
    [Route("api/[controller]")]
    [ApiController]
    public class AuditController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public AuditController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<AuditLog>>> GetLogs()
        {
            return await _context.AuditLogs
                .Include(a => a.Usuario)
                .OrderByDescending(a => a.Fecha)
                .Take(100)
                .ToListAsync();
        }
    }
}
