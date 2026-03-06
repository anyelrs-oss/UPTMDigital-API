using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AnunciosController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public AnunciosController(UPTMDigitalContext context)
        {
            _context = context;
        }

        // GET: api/Anuncios
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Anuncio>>> GetAnuncios()
        {
            return await _context.Anuncios.OrderByDescending(a => a.FechaPublicacion).ToListAsync();
        }

        // POST: api/Anuncios
        [HttpPost]
        public async Task<ActionResult<Anuncio>> PostAnuncio(Anuncio anuncio)
        {
            anuncio.FechaPublicacion = DateTime.Now;
            _context.Anuncios.Add(anuncio);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetAnuncios", new { id = anuncio.IdAnuncio }, anuncio);
        }
    }
}
