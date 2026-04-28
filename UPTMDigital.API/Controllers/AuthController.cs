// Controllers/AuthController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using UPTMDigital.API.Data;
using UPTMDigital.API.DTOs;
using UPTMDigital.API.Models;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;
        private readonly NominaContext _nominaContext;
        private readonly IConfiguration _config;

        public AuthController(UPTMDigitalContext context, NominaContext nominaContext, IConfiguration config)
        {
            _context = context;
            _nominaContext = nominaContext;
            _config = config;
        }

        [HttpPost("login")]
        public async Task<ActionResult<LoginResponseDto>> Login(LoginDto login)
        {
            Console.WriteLine($"[LOGIN ATTEMPT] User: {login.NombreUsuario}, Pass: {login.Contrasena}");

            Usuario? usuario;

            try
            {
                usuario = await _context.Usuarios
                    .Include(u => u.Rol)
                    .FirstOrDefaultAsync(u => u.NombreUsuario == login.NombreUsuario);
            }
            catch (Exception ex) when (IsTransientDbException(ex))
            {
                Console.WriteLine($"[LOGIN RETRYABLE FAILURE] {ex.GetType().Name}: {ex.Message}");
                return StatusCode(StatusCodes.Status503ServiceUnavailable, new
                {
                    Message = "Servicio temporalmente no disponible. Intente de nuevo en unos segundos."
                });
            }

            if (usuario == null)
            {
                Console.WriteLine("[LOGIN FAILED] User not found in database.");
                return NotFound(new { Message = "El usuario ingresado no existe." });
            }

            Console.WriteLine($"[LOGIN FOUND] User: {usuario.NombreUsuario}, Hash: {usuario.ContrasenaHash}");

            bool isPasswordValid = usuario.ContrasenaHash == login.Contrasena;
            Console.WriteLine($"[LOGIN VERIFY] Result: {isPasswordValid}");

            if (!isPasswordValid)
            {
                Console.WriteLine("[LOGIN FAILED] Password mismatch.");
                return Unauthorized(new { Message = "La contraseña es incorrecta." });
            }

            // Explicitly load role if it's null (sometimes .Include fails on lazy setups)
            if (usuario.Rol == null && usuario.RolId > 0)
            {
                usuario.Rol = await _context.Roles.FindAsync(usuario.RolId);
            }

            var roleName = usuario.Rol?.NombreRol ?? "Estudiante"; // Fallback to prevent 500

            var token = GenerarToken(usuario);

            return Ok(new LoginResponseDto
            {
                Token = token,
                Expiracion = DateTime.UtcNow.AddDays(30),
                NombreUsuario = usuario.NombreUsuario,
                Rol = roleName
            });
        }

        private static bool IsTransientDbException(Exception ex)
        {
            if (ex is TimeoutException || ex is NpgsqlException)
            {
                return true;
            }

            if (ex is InvalidOperationException && ex.InnerException is NpgsqlException)
            {
                return true;
            }

            return ex.InnerException is TimeoutException || ex.InnerException is NpgsqlException;
        }

        private string GenerarToken(Models.Usuario usuario)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                _config["Jwt:Key"] ?? "MiClaveSuperSecretaDe32Caracteres1234"));

            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var roleName = usuario.Rol?.NombreRol ?? "Estudiante"; // Fallback for safety

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, usuario.IdUsuario.ToString()),
                new Claim(ClaimTypes.Name, usuario.NombreUsuario),
                new Claim(ClaimTypes.Role, roleName)
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddDays(30),
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
        /// <summary>
        /// Pre-validación de cédula: consulta la Base Maestro (NominaContext)
        /// y verifica si ya tiene cuenta en la App (UPTMDigitalContext).
        /// </summary>
        [HttpGet("check-cedula/{cedula}")]
        public async Task<IActionResult> CheckCedula(string cedula)
        {
            // Buscar en la Base Maestro de Nómina
            var record = await _nominaContext.RegistrosInstitucionales
                .FirstOrDefaultAsync(r => r.Cedula == cedula);

            if (record == null)
                return NotFound(new { Message = "Cédula no encontrada en el registro institucional de la UPTM." });

            // Verificar si ya tiene cuenta creada en la App (buscando en Usuarios)
            var yaTieneCuenta = await _context.Usuarios.AnyAsync(u => u.Cedula == cedula);

            return Ok(new
            {
                Nombres = record.Nombres,
                Apellidos = record.Apellidos,
                Rol = record.RolEsperado,
                Carrera = record.CarreraDepartamento,
                YaTieneCuenta = yaTieneCuenta
            });
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto register)
        {
            // 1. Check if user already exists
            if (await _context.Usuarios.AnyAsync(u => u.NombreUsuario == register.Username))
                return BadRequest(new { Message = "El nombre de usuario ya está en uso." });

            // 2. Validate against Nómina (Base Maestro via NominaContext)
            var institutionalRecord = await _nominaContext.RegistrosInstitucionales
                .FirstOrDefaultAsync(r => r.Cedula == register.Cedula);

            if (institutionalRecord == null)
                return BadRequest(new { Message = "Cédula no encontrada en el registro institucional de la UPTM." });

            var yaRegistrado = await _context.Usuarios.AnyAsync(u => u.Cedula == register.Cedula);
            if (yaRegistrado)
                return BadRequest(new { Message = "Esta cédula ya tiene una cuenta registrada." });

            // 4. Determine Role ID (supports Estudiante, Profesor, Seguridad)
            var roleName = institutionalRecord.RolEsperado;
            if (roleName != "Profesor" && roleName != "Seguridad")
                roleName = "Estudiante"; // Default fallback

            var roleNode = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == roleName);

            if (roleNode == null) return BadRequest(new { Message = "Rol no configurado en el sistema." });

            // 5. Create User Account (linked to Cedula)
            var newUser = new Usuario
            {
                NombreUsuario = register.Username,
                ContrasenaHash = register.Contrasena,
                Cedula = register.Cedula,
                RolId = roleNode.IdRol,
                EstadoCuenta = true,
                UltimoAcceso = DateTime.Now
            };

            _context.Usuarios.Add(newUser);
            await _context.SaveChangesAsync();

            // 6. Create Profile (Estudiante, Profesor, or none for Seguridad)
            if (roleName == "Estudiante")
            {
                _context.Estudiantes.Add(new Estudiante
                {
                    Cedula = institutionalRecord.Cedula,
                    Nombres = institutionalRecord.Nombres,
                    Apellidos = institutionalRecord.Apellidos,
                    CorreoInstitucional = institutionalRecord.CorreoInstitucional,
                    UsuarioId = newUser.IdUsuario,
                    FechaRegistro = DateTime.Now
                });
            }
            else if (roleName == "Profesor")
            {
                _context.Profesores.Add(new Profesor
                {
                    Cedula = institutionalRecord.Cedula,
                    Nombres = institutionalRecord.Nombres,
                    Apellidos = institutionalRecord.Apellidos,
                    Departamento = institutionalRecord.CarreraDepartamento,
                    CorreoInstitucional = institutionalRecord.CorreoInstitucional,
                    UsuarioId = newUser.IdUsuario
                });
            }
            // Seguridad: no profile needed, only Usuario with correct RolId

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Registro completado con éxito. Ya puede iniciar sesión.",
                Rol = roleName,
                Nombres = institutionalRecord.Nombres,
                Apellidos = institutionalRecord.Apellidos
            });
        }
    }
}