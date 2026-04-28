using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Authorize(Roles = "Administrador,SuperAdmin")]
    [Route("api/[controller]")]
    [ApiController]
    public class UsuariosController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public UsuariosController(UPTMDigitalContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Lista usuarios con filtros opcionales.
        /// ?search=texto&rol=Estudiante&activo=true
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetUsuarios(
            [FromQuery] string? search,
            [FromQuery] string? rol,
            [FromQuery] bool? activo)
        {
            var query = _context.Usuarios
                .Include(u => u.Rol)
                .AsNoTracking()
                .AsQueryable();

            // Filtrar por estado activo (por defecto solo activos)
            if (activo.HasValue)
                query = query.Where(u => u.Activo == activo.Value);
            else
                query = query.Where(u => u.Activo);

            // Filtrar por rol
            if (!string.IsNullOrEmpty(rol))
                query = query.Where(u => u.Rol.NombreRol == rol);

            // Búsqueda por nombre de usuario o cédula
            if (!string.IsNullOrEmpty(search))
            {
                var s = search.ToLower();
                query = query.Where(u =>
                    u.NombreUsuario.ToLower().Contains(s) ||
                    (u.Cedula != null && u.Cedula.ToLower().Contains(s)));
            }

            var usuarios = await query
                .OrderBy(u => u.NombreUsuario)
                .Select(u => new
                {
                    u.IdUsuario,
                    u.NombreUsuario,
                    u.Cedula,
                    Rol = u.Rol.NombreRol,
                    u.RolId,
                    u.EstadoCuenta,
                    u.Activo,
                    u.UltimoAcceso
                })
                .ToListAsync();

            return Ok(usuarios);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUsuario(int id)
        {
            var usuario = await _context.Usuarios
                .Include(u => u.Rol)
                .FirstOrDefaultAsync(u => u.IdUsuario == id);

            if (usuario == null) return NotFound();

            return Ok(new
            {
                usuario.IdUsuario,
                usuario.NombreUsuario,
                usuario.Cedula,
                Rol = usuario.Rol.NombreRol,
                usuario.RolId,
                usuario.EstadoCuenta,
                usuario.Activo,
                usuario.UltimoAcceso
            });
        }

        /// <summary>
        /// Modificar usuario (cambiar rol, activar/desactivar).
        /// </summary>
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUsuario(int id, [FromBody] UpdateUsuarioDto dto)
        {
            var usuario = await _context.Usuarios.FindAsync(id);
            if (usuario == null) return NotFound();

            if (dto.RolId.HasValue) usuario.RolId = dto.RolId.Value;
            if (dto.EstadoCuenta.HasValue) usuario.EstadoCuenta = dto.EstadoCuenta.Value;
            if (dto.Activo.HasValue) usuario.Activo = dto.Activo.Value;

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Usuario actualizado." });
        }

        /// <summary>
        /// Soft delete: marca como inactivo.
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUsuario(int id)
        {
            var usuario = await _context.Usuarios.FindAsync(id);
            if (usuario == null) return NotFound();

            usuario.Activo = false;
            usuario.EstadoCuenta = false;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Usuario desactivado." });
        }

        /// <summary>
        /// Reset de contraseña (admin fuerza una nueva).
        /// </summary>
        [HttpPost("{id}/reset-password")]
        public async Task<IActionResult> ResetPassword(int id, [FromBody] ResetPasswordDto dto)
        {
            var usuario = await _context.Usuarios.FindAsync(id);
            if (usuario == null) return NotFound();

            usuario.ContrasenaHash = dto.NuevaContrasena; // Plaintext for dev/staging
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Contraseña restablecida." });
        }
    }

    // DTOs inline for simplicity
    public class UpdateUsuarioDto
    {
        public int? RolId { get; set; }
        public bool? EstadoCuenta { get; set; }
        public bool? Activo { get; set; }
    }

    public class ResetPasswordDto
    {
        public string NuevaContrasena { get; set; } = null!;
    }
}
