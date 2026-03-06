using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MensajesController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public MensajesController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // GET: api/Mensajes/{asignaturaId}
        [HttpGet("{asignaturaId}")]
        public async Task<ActionResult<IEnumerable<Mensaje>>> GetMensajes(int asignaturaId)
        {
            return await _context.Mensajes
                .Where(m => m.AsignaturaId == asignaturaId)
                .OrderBy(m => m.FechaEnvio)
                .ToListAsync();
        }

        // POST: api/Mensajes
        [HttpPost]
        public async Task<ActionResult<Mensaje>> PostMensaje(Mensaje mensaje)
        {
            mensaje.FechaEnvio = DateTime.Now;
            _context.Mensajes.Add(mensaje);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetMensajes", new { asignaturaId = mensaje.AsignaturaId }, mensaje);
        }
    }
}
