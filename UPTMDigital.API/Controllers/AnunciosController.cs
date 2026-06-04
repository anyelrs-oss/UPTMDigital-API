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
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var roleName = User.FindFirst(ClaimTypes.Role)?.Value;

            var query = _context.Anuncios.Where(a => a.Activo).AsQueryable();

            if (!string.IsNullOrEmpty(roleName) && roleName != "Administrador")
            {
                // Buscamos el ID del rol del usuario
                var rol = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == roleName);

                // Filtramos por rol y carrera si es estudiante
                if (roleName == "Estudiante" && int.TryParse(userIdStr, out var userId))
                {
                    var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioId == userId);
                    query = query.Where(a =>
                        (a.RolId == null || a.RolId == rol.IdRol) &&
                        (a.CarreraId == null || (estudiante != null && a.CarreraId == estudiante.CarreraId))
                    );
                }
                else if (rol != null)
                {
                    query = query.Where(a => a.RolId == null || a.RolId == rol.IdRol);
                }
            }

            return await query.OrderByDescending(a => a.Prioridad == "Critica")
                              .ThenByDescending(a => a.Prioridad == "Urgente")
                              .ThenByDescending(a => a.FechaPublicacion)
                              .ToListAsync();
        }

        // POST: api/Anuncios
        [HttpPost]
        public async Task<ActionResult<Anuncio>> PostAnuncio(Anuncio anuncio)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdStr, out var userId))
            {
                anuncio.UsuarioId = userId;

                // Si el autor viene vacío, intentamos poner el nombre del usuario logueado
                if (string.IsNullOrEmpty(anuncio.Autor))
                {
                    var user = await _context.Usuarios.FindAsync(userId);
                    anuncio.Autor = user?.NombreUsuario ?? "Administrador";
                }
            }

            anuncio.FechaPublicacion = DateTime.UtcNow;
            anuncio.Activo = true;

            _context.Anuncios.Add(anuncio);
            await _context.SaveChangesAsync();

            return Ok(anuncio);
        }
    }
}
