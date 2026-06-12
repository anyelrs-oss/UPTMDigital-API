using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SetupController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public sealed class SeedAuthRequest
        {
            public string Username { get; set; } = "tester1";
            public string Password { get; set; } = "123456";
            public string RoleName { get; set; } = "Estudiante";
        }

        public SetupController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpPost("seed-test-users")]
        public async Task<IActionResult> SeedTestUsers()
        {
            var log = new List<string>();

            var strategy = _context.Database.CreateExecutionStrategy();
            try
            {
                await strategy.ExecuteAsync(async () =>
                {
                    await using var tx = await _context.Database.BeginTransactionAsync();

                    await EnsureRoleAsync("Administrador");
                    await EnsureRoleAsync("Profesor");
                    await EnsureRoleAsync("Estudiante");
                    await EnsureRoleAsync("Seguridad");
                    await EnsureRoleAsync("Coordinador");
                    await EnsureRoleAsync("Secretaria");

                    await EnsureUserWithRoleAsync("tester_admin", "123456", "Administrador", log);
                    await EnsureUserWithRoleAsync("tester_seg",   "123456", "Seguridad",     log);
                    await EnsureUserWithRoleAsync("tester_prof",  "123456", "Profesor",      log);
                    await EnsureUserWithRoleAsync("tester_est",   "123456", "Estudiante",    log);
                    await EnsureUserWithRoleAsync("tester_coord", "123456", "Coordinador",   log);
                    await EnsureUserWithRoleAsync("tester_sec",   "123456", "Secretaria",    log);

                    await EnsureProfesorProfileAsync("tester_prof", log);
                    await EnsureEstudianteProfileAsync("tester_est", log);
                    await EnsureCoordinadorProfileAsync("tester_coord", log);

                    await _context.SaveChangesAsync();
                    await tx.CommitAsync();
                });
            }
            catch (Exception ex) when (IsTransientDbException(ex))
            {
                return StatusCode(StatusCodes.Status503ServiceUnavailable, new
                {
                    message = "No se pudo sembrar usuarios de prueba por una falla transitoria de base de datos. Reintente en unos segundos.",
                    detail = ex.Message
                });
            }

            return Ok(new
            {
                message = "Test users seeded/updated.",
                credentials = new[]
                {
                    new { username = "tester_admin", password = "123456", role = "Administrador" },
                    new { username = "tester_seg",   password = "123456", role = "Seguridad" },
                    new { username = "tester_prof",  password = "123456", role = "Profesor" },
                    new { username = "tester_est",   password = "123456", role = "Estudiante" },
                    new { username = "tester_coord", password = "123456", role = "Coordinador" },
                    new { username = "tester_sec",   password = "123456", role = "Secretaria" }
                },
                log
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

        [HttpPost("seed-auth-test")]
        public async Task<IActionResult> SeedAuthTest([FromBody] SeedAuthRequest? request)
        {
            var payload = request ?? new SeedAuthRequest();
            var roleName = string.IsNullOrWhiteSpace(payload.RoleName) ? "Estudiante" : payload.RoleName.Trim();

            var role = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == roleName);
            if (role == null)
            {
                role = new Rol { NombreRol = roleName };
                _context.Roles.Add(role);
                await _context.SaveChangesAsync();
            }

            var existing = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == payload.Username);
            if (existing != null)
            {
                existing.ContrasenaHash = payload.Password;
                existing.RolId = role.IdRol;
                existing.EstadoCuenta = true;
                existing.UltimoAcceso = DateTime.UtcNow;
                _context.Entry(existing).State = EntityState.Modified;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Test user updated.",
                    username = existing.NombreUsuario,
                    role = role.NombreRol,
                    password = payload.Password
                });
            }

            var user = new Usuario
            {
                NombreUsuario = payload.Username,
                ContrasenaHash = payload.Password,
                RolId = role.IdRol,
                EstadoCuenta = true,
                UltimoAcceso = DateTime.UtcNow
            };

            _context.Usuarios.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Test user created.",
                username = user.NombreUsuario,
                role = role.NombreRol,
                password = payload.Password
            });
        }

        private async Task EnsureRoleAsync(string roleName)
        {
            if (!await _context.Roles.AnyAsync(r => r.NombreRol == roleName))
            {
                _context.Roles.Add(new Rol { NombreRol = roleName });
                await _context.SaveChangesAsync();
            }
        }

        private async Task EnsureUserWithRoleAsync(string username, string password, string roleName, List<string> log)
        {
            var role = await _context.Roles.FirstAsync(r => r.NombreRol == roleName);
            var user = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == username);

            if (user == null)
            {
                user = new Usuario
                {
                    NombreUsuario = username,
                    ContrasenaHash = password,
                    RolId = role.IdRol,
                    EstadoCuenta = true,
                    UltimoAcceso = DateTime.UtcNow
                };
                _context.Usuarios.Add(user);
                log.Add($"Created user '{username}' with role '{roleName}'.");
                return;
            }

            user.ContrasenaHash = password;
            user.RolId = role.IdRol;
            user.EstadoCuenta = true;
            user.UltimoAcceso = DateTime.UtcNow;
            _context.Entry(user).State = EntityState.Modified;
            log.Add($"Updated user '{username}' with role '{roleName}'.");
        }

        private async Task EnsureProfesorProfileAsync(string username, List<string> log)
        {
            var usr = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == username);
            if (usr == null) return;
            var profile = await _context.Profesores.FirstOrDefaultAsync(p => p.UsuarioId == usr.IdUsuario);
            if (profile != null) return;

            _context.Profesores.Add(new Profesor
            {
                Cedula = "V-44444444",
                Nombres = "Test",
                Apellidos = "Profesor",
                CorreoInstitucional = "tester.prof@uptm.edu.ve",
                Departamento = "Informatica",
                Telefono = "0412-4444444",
                UsuarioId = usr.IdUsuario
            });
            log.Add($"Created professor profile linked to '{username}'.");
        }

        private async Task EnsureEstudianteProfileAsync(string username, List<string> log)
        {
            var usr = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == username);
            if (usr == null) return;
            var profile = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioId == usr.IdUsuario);
            if (profile != null) return;

            _context.Estudiantes.Add(new Estudiante
            {
                Cedula = "V-55555555",
                Nombres = "Test",
                Apellidos = "Estudiante",
                CorreoInstitucional = "tester.est@uptm.edu.ve",
                Direccion = "Merida",
                Telefono = "0412-5555555",
                FechaRegistro = DateTime.UtcNow,
                UsuarioId = usr.IdUsuario
            });
            log.Add($"Created student profile linked to '{username}'.");
        }

        private async Task EnsureCoordinadorProfileAsync(string username, List<string> log)
        {
            var usr = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == username);
            if (usr == null) return;
            var profile = await _context.Coordinadores.FirstOrDefaultAsync(c => c.UsuarioId == usr.IdUsuario);
            if (profile != null) return;

            _context.Coordinadores.Add(new Coordinador
            {
                Nombres = "Test",
                Apellidos = "Coordinador",
                UsuarioId = usr.IdUsuario,
                Activo = true
            });
            log.Add($"Created coordinator profile linked to '{username}'.");
        }

        // ── SEED PASO 1: Roles + Profesores + Estudiantes ────────────────────────
        [HttpPost("seed-base")]
        public async Task<IActionResult> SeedBase()
        {
            var log = new List<string>();
            try
            {
                foreach (var r in new[] { "Administrador", "Profesor", "Estudiante", "Seguridad" })
                    if (!await _context.Roles.AnyAsync(x => x.NombreRol == r))
                        _context.Roles.Add(new Rol { NombreRol = r });
                await _context.SaveChangesAsync();
                log.Add("Roles OK.");

                var rolProf = await _context.Roles.FirstAsync(r => r.NombreRol == "Profesor");
                var rolEst  = await _context.Roles.FirstAsync(r => r.NombreRol == "Estudiante");

                var profData = new[] {
                    ("prof_garcia",  "V-12345678", "Carlos",    "García",    "c.garcia@uptm.edu.ve",  "Informática",   "P001", "0412-1234567"),
                    ("prof_mendoza", "V-18765432", "María",     "Mendoza",   "m.mendoza@uptm.edu.ve", "Matemáticas",   "P002", "0416-7654321"),
                    ("prof_torres",  "V-14523678", "Luis",      "Torres",    "l.torres@uptm.edu.ve",  "Sistemas",      "P003", "0424-5236781"),
                    ("prof_ramirez", "V-20134576", "Ana",       "Ramírez",   "a.ramirez@uptm.edu.ve", "Ingeniería",    "P004", "0426-3415762"),
                };
                foreach (var (lg, ced, nom, ape, cor, dep, cod, tel) in profData) {
                    if (!await _context.Usuarios.AnyAsync(u => u.NombreUsuario == lg))
                        _context.Usuarios.Add(new Usuario { NombreUsuario=lg, ContrasenaHash="123456", RolId=rolProf.IdRol, EstadoCuenta=true, UltimoAcceso=DateTime.UtcNow });
                }
                await _context.SaveChangesAsync();
                foreach (var (lg, ced, nom, ape, cor, dep, cod, tel) in profData) {
                    if (!await _context.Profesores.AnyAsync(x => x.Cedula == ced)) {
                        var usr = await _context.Usuarios.FirstAsync(u => u.NombreUsuario == lg);
                        _context.Profesores.Add(new Profesor { Cedula=ced, Nombres=nom, Apellidos=ape, CorreoInstitucional=cor, Departamento=dep, CodProfesor=cod, Telefono=tel, UsuarioId=usr.IdUsuario });
                    }
                }
                await _context.SaveChangesAsync();
                log.Add($"Profesores: {profData.Length} asegurados.");

                var estData = new[] {
                    ("est_rodriguez", "V-27112233", "Daniela",   "Rodríguez", "d.rodriguez@uptm.edu.ve", "Informática",    "20230001", "Av. Principal, Mérida",    "0412-9988776"),
                    ("est_lopez",     "V-28990011", "Andrés",    "López",     "a.lopez@uptm.edu.ve",     "Informática",    "20230002", "Urb. La Floresta, Mérida", "0416-1122334"),
                    ("est_fernandez", "V-29445566", "Valentina", "Fernández", "v.fernandez@uptm.edu.ve", "Administración", "20230003", "Bella Vista, Mérida",      "0424-5566778"),
                    ("est_perez",     "V-26778899", "Miguel",    "Pérez",     "m.perez@uptm.edu.ve",     "Administración", "20230004", "Res. Los Pinos, Mérida",  "0426-7788990"),
                    ("est_morales",   "V-30123456", "Gabriela",  "Morales",   "g.morales@uptm.edu.ve",   "Contaduría",     "20230005", "Calle 3, El Vigía",        "0412-3344556"),
                    ("est_vargas",    "V-25667788", "José",      "Vargas",    "j.vargas@uptm.edu.ve",    "Informática",    "20220010", "Edif. Las Palmas, Mérida", "0416-6677889"),
                };
                foreach (var (lg, ced, nom, ape, cor, car, coda, dir, tel) in estData) {
                    if (!await _context.Usuarios.AnyAsync(u => u.NombreUsuario == lg))
                        _context.Usuarios.Add(new Usuario { NombreUsuario=lg, ContrasenaHash="123456", RolId=rolEst.IdRol, EstadoCuenta=true, UltimoAcceso=DateTime.UtcNow });
                }
                await _context.SaveChangesAsync();
                foreach (var (lg, ced, nom, ape, cor, car, coda, dir, tel) in estData) {
                    if (!await _context.Estudiantes.AnyAsync(x => x.Cedula == ced)) {
                        var usr = await _context.Usuarios.FirstAsync(u => u.NombreUsuario == lg);
                        _context.Estudiantes.Add(new Estudiante { Cedula=ced, Nombres=nom, Apellidos=ape, CorreoInstitucional=cor, CodAlumno=coda, Direccion=dir, Telefono=tel, FechaRegistro=DateTime.UtcNow, UsuarioId=usr.IdUsuario });
                    }
                }
                await _context.SaveChangesAsync();
                log.Add($"Estudiantes: {estData.Length} asegurados.");
            }
            catch (Exception ex) { return StatusCode(500, new { step="seed-base", error=ex.Message, log }); }
            return Ok(new { message="Paso 1 OK. Llama seed-academico a continuación.", log });
        }

        // ── SEED PASO 2: Asignaturas + Horarios + Inscripciones ──────────────────
        [HttpPost("seed-academico")]
        public async Task<IActionResult> SeedAcademico()
        {
            var log = new List<string>();
            try
            {
                var p1 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == "V-12345678");
                var p2 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == "V-18765432");
                var p3 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == "V-14523678");
                var p4 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == "V-20134576");
                if (p1==null||p2==null||p3==null||p4==null)
                    return BadRequest(new { message="Ejecuta seed-base primero.", log });

                async Task<Asignatura> GA(string cod, string nom, int cred, int sem, string dep, int pid) {
                    var a = await _context.Asignaturas.FirstOrDefaultAsync(x => x.Codigo == cod);
                    if (a == null) { a = new Asignatura { Codigo=cod,Nombre=nom,Creditos=cred,Departamento=dep,ProfesorId=pid }; _context.Asignaturas.Add(a); await _context.SaveChangesAsync(); }
                    return a;
                }
                var a1  = await GA("INF101","Introducción a la Informática",  3,1,"Informática",   p1.IdProfesor);
                var a2  = await GA("PRG101","Algoritmos y Programación I",     4,1,"Informática",   p1.IdProfesor);
                var a3  = await GA("PRG201","Programación Orientada a Objetos",4,2,"Informática",   p3.IdProfesor);
                var a4  = await GA("BD201", "Base de Datos I",                 3,3,"Informática",   p3.IdProfesor);
                var a5  = await GA("MAT101","Cálculo I",                       4,1,"Matemáticas",   p2.IdProfesor);
                var a7  = await GA("ADM101","Principios de Administración",    3,1,"Administración",p4.IdProfesor);
                var a8  = await GA("ADM201","Contabilidad General",            3,2,"Administración",p4.IdProfesor);
                var a9  = await GA("ING101","Inglés Técnico I",                2,1,"Idiomas",       p2.IdProfesor);
                var a10 = await GA("SIS301","Redes y Comunicaciones",          3,4,"Sistemas",      p3.IdProfesor);
                log.Add("Asignaturas: 9 aseguradas.");

                if (!await _context.Horarios.AnyAsync()) {
                    _context.Horarios.AddRange(
                        new Horario{AsignaturaId=a1.IdAsignatura,Dia="Lunes",    HoraInicio="07:00",HoraFin="09:00",Aula="Aula 01"},
                        new Horario{AsignaturaId=a1.IdAsignatura,Dia="Miércoles",HoraInicio="07:00",HoraFin="09:00",Aula="Aula 01"},
                        new Horario{AsignaturaId=a2.IdAsignatura,Dia="Lunes",    HoraInicio="09:00",HoraFin="11:00",Aula="Lab Computación"},
                        new Horario{AsignaturaId=a2.IdAsignatura,Dia="Viernes",  HoraInicio="09:00",HoraFin="11:00",Aula="Lab Computación"},
                        new Horario{AsignaturaId=a3.IdAsignatura,Dia="Martes",   HoraInicio="11:00",HoraFin="13:00",Aula="Lab Computación"},
                        new Horario{AsignaturaId=a5.IdAsignatura,Dia="Martes",   HoraInicio="07:00",HoraFin="09:00",Aula="Aula 05"},
                        new Horario{AsignaturaId=a5.IdAsignatura,Dia="Jueves",   HoraInicio="07:00",HoraFin="09:00",Aula="Aula 05"},
                        new Horario{AsignaturaId=a7.IdAsignatura,Dia="Miércoles",HoraInicio="13:00",HoraFin="15:00",Aula="Aula 08"},
                        new Horario{AsignaturaId=a9.IdAsignatura,Dia="Jueves",   HoraInicio="15:00",HoraFin="17:00",Aula="Aula 02"},
                        new Horario{AsignaturaId=a10.IdAsignatura,Dia="Viernes", HoraInicio="11:00",HoraFin="13:00",Aula="Lab Redes"}
                    );
                    await _context.SaveChangesAsync();
                    log.Add("Horarios: 10 creados.");
                }

                if (!await _context.Inscripciones.AnyAsync()) {
                    var e1 = await _context.Estudiantes.FirstAsync(e => e.Cedula=="V-27112233");
                    var e2 = await _context.Estudiantes.FirstAsync(e => e.Cedula=="V-28990011");
                    var e3 = await _context.Estudiantes.FirstAsync(e => e.Cedula=="V-29445566");
                    var e4 = await _context.Estudiantes.FirstAsync(e => e.Cedula=="V-26778899");
                    var e5 = await _context.Estudiantes.FirstAsync(e => e.Cedula=="V-30123456");
                    var e6 = await _context.Estudiantes.FirstAsync(e => e.Cedula=="V-25667788");
                    _context.Inscripciones.AddRange(
                        new Inscripcion{EstudianteId=e1.IdEstudiante,AsignaturaId=a1.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e1.IdEstudiante,AsignaturaId=a2.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e1.IdEstudiante,AsignaturaId=a5.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e1.IdEstudiante,AsignaturaId=a9.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e2.IdEstudiante,AsignaturaId=a1.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e2.IdEstudiante,AsignaturaId=a2.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e2.IdEstudiante,AsignaturaId=a3.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e6.IdEstudiante,AsignaturaId=a3.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e6.IdEstudiante,AsignaturaId=a4.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e6.IdEstudiante,AsignaturaId=a10.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e3.IdEstudiante,AsignaturaId=a7.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e3.IdEstudiante,AsignaturaId=a8.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e3.IdEstudiante,AsignaturaId=a5.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e4.IdEstudiante,AsignaturaId=a7.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e4.IdEstudiante,AsignaturaId=a9.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e5.IdEstudiante,AsignaturaId=a8.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"},
                        new Inscripcion{EstudianteId=e5.IdEstudiante,AsignaturaId=a5.IdAsignatura,FechaInscripcion=DateTime.UtcNow,Estado="Activo"}
                    );
                    await _context.SaveChangesAsync();
                    log.Add("Inscripciones: 17 creadas.");
                }
            }
            catch (Exception ex) { return StatusCode(500, new { step="seed-academico", error=ex.Message, log }); }
            return Ok(new { message="Paso 2 OK. Llama seed-extra a continuación.", log });
        }

        // ── SEED PASO 3: Notas + Anuncios + Asistencias + Constancias + Accesos ──
        [HttpPost("seed-extra")]
        public async Task<IActionResult> SeedExtra()
        {
            var log = new List<string>();
            try
            {
                var e1 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula=="V-27112233");
                var e2 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula=="V-28990011");
                var e3 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula=="V-29445566");
                var e4 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula=="V-26778899");
                var e5 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula=="V-30123456");
                var e6 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula=="V-25667788");
                var p1 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula=="V-12345678");
                var p2 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula=="V-18765432");
                var p3 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula=="V-14523678");
                var p4 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula=="V-20134576");
                if (e1==null||p1==null)
                    return BadRequest(new { message="Ejecuta seed-base y seed-academico primero.", log });

                var a1=await _context.Asignaturas.FirstAsync(a=>a.Codigo=="INF101");
                var a2=await _context.Asignaturas.FirstAsync(a=>a.Codigo=="PRG101");
                var a3=await _context.Asignaturas.FirstAsync(a=>a.Codigo=="PRG201");
                var a4=await _context.Asignaturas.FirstAsync(a=>a.Codigo=="BD201");
                var a5=await _context.Asignaturas.FirstAsync(a=>a.Codigo=="MAT101");
                var a7=await _context.Asignaturas.FirstAsync(a=>a.Codigo=="ADM101");
                var a8=await _context.Asignaturas.FirstAsync(a=>a.Codigo=="ADM201");

                if (!await _context.Notas.AnyAsync()) {
                    _context.Notas.AddRange(
                        new Nota{EstudianteId=e1!.IdEstudiante,AsignaturaId=a1.IdAsignatura,ProfesorId=p1!.IdProfesor,Calificacion=18,Fecha=DateTime.UtcNow.AddDays(-20),CodigoQR="QR-INF101-001"},
                        new Nota{EstudianteId=e1.IdEstudiante, AsignaturaId=a2.IdAsignatura,ProfesorId=p1.IdProfesor, Calificacion=16,Fecha=DateTime.UtcNow.AddDays(-15),CodigoQR="QR-PRG101-001"},
                        new Nota{EstudianteId=e1.IdEstudiante, AsignaturaId=a5.IdAsignatura,ProfesorId=p2!.IdProfesor,Calificacion=14,Fecha=DateTime.UtcNow.AddDays(-10),CodigoQR="QR-MAT101-001"},
                        new Nota{EstudianteId=e2!.IdEstudiante,AsignaturaId=a1.IdAsignatura,ProfesorId=p1.IdProfesor, Calificacion=20,Fecha=DateTime.UtcNow.AddDays(-20),CodigoQR="QR-INF101-002"},
                        new Nota{EstudianteId=e2.IdEstudiante, AsignaturaId=a2.IdAsignatura,ProfesorId=p1.IdProfesor, Calificacion=15,Fecha=DateTime.UtcNow.AddDays(-15),CodigoQR="QR-PRG101-002"},
                        new Nota{EstudianteId=e2.IdEstudiante, AsignaturaId=a3.IdAsignatura,ProfesorId=p3!.IdProfesor,Calificacion=17,Fecha=DateTime.UtcNow.AddDays(-8), CodigoQR="QR-PRG201-001"},
                        new Nota{EstudianteId=e3!.IdEstudiante,AsignaturaId=a7.IdAsignatura,ProfesorId=p4!.IdProfesor,Calificacion=19,Fecha=DateTime.UtcNow.AddDays(-12),CodigoQR="QR-ADM101-001"},
                        new Nota{EstudianteId=e4!.IdEstudiante,AsignaturaId=a7.IdAsignatura,ProfesorId=p4.IdProfesor, Calificacion=13,Fecha=DateTime.UtcNow.AddDays(-12),CodigoQR="QR-ADM101-002"},
                        new Nota{EstudianteId=e5!.IdEstudiante,AsignaturaId=a8.IdAsignatura,ProfesorId=p4.IdProfesor, Calificacion=11,Fecha=DateTime.UtcNow.AddDays(-5), CodigoQR="QR-ADM201-001"},
                        new Nota{EstudianteId=e6!.IdEstudiante,AsignaturaId=a3.IdAsignatura,ProfesorId=p3.IdProfesor, Calificacion=18,Fecha=DateTime.UtcNow.AddDays(-8), CodigoQR="QR-PRG201-002"}
                    );
                    await _context.SaveChangesAsync();
                    log.Add("Notas: 10 creadas.");
                }

                if (!await _context.Anuncios.AnyAsync()) {
                    _context.Anuncios.AddRange(
                        new Anuncio{Titulo="Bienvenida al Período Académico 2025-I",Contenido="La UPTM Mérida da la bienvenida a toda la comunidad universitaria al inicio del período 2025-I.",FechaPublicacion=DateTime.UtcNow.AddDays(-30),Autor="Rectorado"},
                        new Anuncio{Titulo="Inicio de Inscripciones — Período 2025-II",Contenido="Las inscripciones para el período 2025-II estarán disponibles del 15 al 30 de junio.",FechaPublicacion=DateTime.UtcNow.AddDays(-10),Autor="Coordinación Académica"},
                        new Anuncio{Titulo="Mantenimiento del Sistema",Contenido="El sistema estará en mantenimiento el sábado 15/03 de 8:00am a 12:00pm.",FechaPublicacion=DateTime.UtcNow.AddDays(-5),Autor="Soporte Técnico"},
                        new Anuncio{Titulo="Convocatoria — Feria de Proyectos Tecnológicos",Contenido="IV Feria de Proyectos Tecnológicos el 25 de abril en el patio principal.",FechaPublicacion=DateTime.UtcNow.AddDays(-2),Autor="Coordinación de Investigación"},
                        new Anuncio{Titulo="Actualización de Notas — Primer Corte",Contenido="Los profesores deben registrar el primer corte antes del 20 del mes en la plataforma.",FechaPublicacion=DateTime.UtcNow.AddDays(-1),Autor="Coordinación Docente"}
                    );
                    await _context.SaveChangesAsync();
                    log.Add("Anuncios: 5 creados.");
                }

                if (!await _context.Asistencias.AnyAsync()) {
                    _context.Asistencias.AddRange(
                        new Asistencia{EstudianteId=e1.IdEstudiante,AsignaturaId=a1.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-14),Estado="Presente"},
                        new Asistencia{EstudianteId=e1.IdEstudiante,AsignaturaId=a1.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-7), Estado="Presente"},
                        new Asistencia{EstudianteId=e1.IdEstudiante,AsignaturaId=a2.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-14),Estado="Presente"},
                        new Asistencia{EstudianteId=e1.IdEstudiante,AsignaturaId=a2.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-7), Estado="Ausente"},
                        new Asistencia{EstudianteId=e2.IdEstudiante,AsignaturaId=a1.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-14),Estado="Presente"},
                        new Asistencia{EstudianteId=e2.IdEstudiante,AsignaturaId=a2.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-7), Estado="Presente"},
                        new Asistencia{EstudianteId=e3.IdEstudiante,AsignaturaId=a7.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-14),Estado="Presente"},
                        new Asistencia{EstudianteId=e3.IdEstudiante,AsignaturaId=a7.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-7), Estado="Ausente"},
                        new Asistencia{EstudianteId=e4.IdEstudiante,AsignaturaId=a7.IdAsignatura,Fecha=DateTime.UtcNow.AddDays(-7), Estado="Presente"}
                    );
                    await _context.SaveChangesAsync();
                    log.Add("Asistencias: 9 creadas.");
                }

                if (!await _context.Constancias.AnyAsync()) {
                    _context.Constancias.AddRange(
                        new Constancia{EstudianteId=e1.IdEstudiante,TipoConstancia="Estudio",       FechaSolicitud=DateTime.UtcNow.AddDays(-20),Estado="Emitida",   CodigoQR="CONST-001"},
                        new Constancia{EstudianteId=e1.IdEstudiante,TipoConstancia="Buena Conducta",FechaSolicitud=DateTime.UtcNow.AddDays(-10),Estado="Emitida",   CodigoQR="CONST-002"},
                        new Constancia{EstudianteId=e2.IdEstudiante,TipoConstancia="Notas",         FechaSolicitud=DateTime.UtcNow.AddDays(-5), Estado="En proceso",CodigoQR="CONST-003"},
                        new Constancia{EstudianteId=e3.IdEstudiante,TipoConstancia="Estudio",       FechaSolicitud=DateTime.UtcNow.AddDays(-3), Estado="Pendiente", CodigoQR="CONST-004"}
                    );
                    await _context.SaveChangesAsync();
                    log.Add("Constancias: 4 creadas.");
                }

                if (!await _context.ControlAccesos.AnyAsync()) {
                    var t0=DateTime.UtcNow.AddDays(-2);
                    var acc=new[]{(e1.Cedula,"Entrada","Bloque A"),(e1.Cedula,"Salida","Bloque A"),(e2.Cedula,"Entrada","Bloque B"),(e2.Cedula,"Salida","Bloque B"),(p1.Cedula,"Entrada","Bloque C — Docentes"),(p1.Cedula,"Salida","Bloque C — Docentes")};
                    for(int i=0;i<acc.Length;i++) _context.ControlAccesos.Add(new ControlAcceso{Cedula=acc[i].Item1,Tipo=acc[i].Item2,Ubicacion=acc[i].Item3,FechaHora=t0.AddHours(i*2)});
                    await _context.SaveChangesAsync();
                    log.Add("ControlAcceso: 6 registros creados.");
                }

                if (!await _context.RegistrosInstitucionales.AnyAsync()) {
                    _context.RegistrosInstitucionales.AddRange(
                        new RegistroInstitucional{Cedula="V-31500001",Nombres="Roberto",Apellidos="Gutiérrez",CarreraDepartamento="Informática",  RolEsperado="Estudiante",CorreoInstitucional="r.gutierrez@uptm.edu.ve"},
                        new RegistroInstitucional{Cedula="V-32100002",Nombres="Sofía",  Apellidos="Acosta",   CarreraDepartamento="Turismo",        RolEsperado="Estudiante",CorreoInstitucional="s.acosta@uptm.edu.ve"},
                        new RegistroInstitucional{Cedula="V-19876543",Nombres="Pedro",  Apellidos="Núñez",    CarreraDepartamento="Matemáticas",   RolEsperado="Profesor",  CorreoInstitucional="p.nunez@uptm.edu.ve"}
                    );
                    await _context.SaveChangesAsync();
                    log.Add("RegistrosInstitucionales: 3 creados.");
                }
            }
            catch (Exception ex) { return StatusCode(500, new { step="seed-extra", error=ex.Message, log }); }
            return Ok(new {
                message="✅ Seed completo. Base de datos lista para pruebas.",
                credenciales=new[]{
                    new{usuarios="prof_garcia / prof_mendoza / prof_torres / prof_ramirez",pass="123456",rol="Profesor"},
                    new{usuarios="est_rodriguez / est_lopez / est_fernandez / est_perez / est_morales / est_vargas",pass="123456",rol="Estudiante"}
                },
                log
            });
        }

        [HttpPost("patch-activo")]
        public async Task<IActionResult> PatchActivo()
        {
            var log = new List<string>();
            try
            {
                var tables = new[] { "Usuario", "Profesor", "Estudiante", "Anuncio", "Asignatura", "Periodo", "Carreras", "Semestres" };
                foreach (var t in tables)
                {
                    try
                    {
                        await _context.Database.ExecuteSqlRawAsync($"ALTER TABLE \"{t}\" ADD COLUMN IF NOT EXISTS \"Activo\" boolean NOT NULL DEFAULT true;");
                        log.Add($"Patched {t} - added Activo column");
                    }
                    catch (Exception ex)
                    {
                        log.Add($"Warning on {t}: {ex.Message}");
                    }
                }
                
                try
                {
                    await _context.Database.ExecuteSqlRawAsync($"ALTER TABLE \"RegistrosInstitucionales\" ADD COLUMN IF NOT EXISTS \"Activo\" boolean NOT NULL DEFAULT true;");
                    log.Add($"Patched RegistrosInstitucionales");
                } catch {}

                return Ok(new { message = "Patch completado", log });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message, stack = ex.ToString(), log });
            }
        }

        [HttpPost("apply-changes")]
        public async Task<IActionResult> ApplyChanges()
        {
            var log = new List<string>();

            // 1. Update Schema and Apply Migrations
            try
            {
                await _context.Database.MigrateAsync();
                log.Add("Schema generation is now handled by EF Core Migrations and was applied successfully.");
            }
            catch (Exception ex)
            {
                log.Add($"Schema update warning: {ex.Message}");
            }

            // 2. Link Data
            try
            {
                // 1.1 Seed Roles (Critical for User Creation)
                var rolesNames = new[] { "Administrador", "Profesor", "Estudiante", "Seguridad", "Secretaria", "SuperAdmin", "Auditor", "Coordinador" };
                foreach (var rName in rolesNames)
                {
                    if (!await _context.Roles.AnyAsync(r => r.NombreRol == rName))
                    {
                        _context.Roles.Add(new Rol { NombreRol = rName });
                    }
                }
                await _context.SaveChangesAsync();
                log.Add("Ensured Roles exist.");
                // Ensure users exist
                var profesorUser = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == "profesor1");
                if (profesorUser == null)
                {
                    var rolProf = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == "Profesor");
                    if (rolProf == null)
                    {
                        rolProf = new Rol { NombreRol = "Profesor" };
                        _context.Roles.Add(rolProf);
                        await _context.SaveChangesAsync();
                    }

                    profesorUser = new Usuario { NombreUsuario = "profesor1", ContrasenaHash = "123456", RolId = rolProf.IdRol, EstadoCuenta = true, UltimoAcceso = DateTime.Now };
                    _context.Usuarios.Add(profesorUser);
                    await _context.SaveChangesAsync();
                    log.Add("Created user 'profesor1'");
                }

                // Ensure Profile
                if (!await _context.Profesores.AnyAsync(p => p.Cedula == "V-99999991"))
                {
                    var newProf = new Profesor
                    {
                        Cedula = "V-99999991",
                        Nombres = "Juan",
                        Apellidos = "Profesor",
                        CorreoInstitucional = "juan@uptm.edu.ve",
                        Telefono = "0412-1111111",
                        UsuarioId = profesorUser.IdUsuario,
                        Departamento = "Informatica"
                    };
                    _context.Profesores.Add(newProf);
                    await _context.SaveChangesAsync();
                    log.Add("Created Professor profile for 'profesor1'");
                }

                var estudianteUser = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == "estudiante1");
                if (estudianteUser == null)
                {
                    // CREATE ESTUDIANTE1
                    var rolEst = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == "Estudiante");
                    if (rolEst != null)
                    {
                        estudianteUser = new Usuario { NombreUsuario = "estudiante1", ContrasenaHash = "123456", RolId = rolEst.IdRol, EstadoCuenta = true, UltimoAcceso = DateTime.Now };
                        _context.Usuarios.Add(estudianteUser);
                        await _context.SaveChangesAsync();
                        log.Add("Created user 'estudiante1'");

                        // Ensure Student Profile
                        if (!await _context.Estudiantes.AnyAsync(e => e.Cedula == "V-15000000"))
                        {
                            var newEst = new Estudiante
                            {
                                Cedula = "V-15000000",
                                Nombres = "Angel",
                                Apellidos = "Estudiante",
                                CorreoInstitucional = "angel@uptm.edu.ve",
                                Direccion = "Mérida",
                                UsuarioId = estudianteUser.IdUsuario
                            };
                            _context.Estudiantes.Add(newEst);
                            await _context.SaveChangesAsync();
                            log.Add("Created Student profile for 'estudiante1'");
                        }
                    }
                }
                else
                {
                    // Link to first student if not linked
                    var estudiante = await _context.Estudiantes.OrderBy(e => e.IdEstudiante).FirstOrDefaultAsync();
                    if (estudiante != null && estudiante.UsuarioId == null)
                    {
                        estudiante.UsuarioId = estudianteUser.IdUsuario;
                        _context.Entry(estudiante).State = EntityState.Modified;
                        log.Add($"Linked user 'estudiante1' to Student ID {estudiante.IdEstudiante} ({estudiante.Nombres})");
                    }
                }

                // FORCE PASSWORD RESET FOR DEBUGGING (Since AuthController uses plain text check)
                var usersToReset = new[] { "profesor1", "profesor2", "estudiante1", "estudiante2", "seguridad1" };
                foreach (var uname in usersToReset)
                {
                    var u = await _context.Usuarios.FirstOrDefaultAsync(x => x.NombreUsuario == uname);
                    if (u != null)
                    {
                        u.ContrasenaHash = "123456"; // Plain text as expected by AuthController.cs
                        _context.Entry(u).State = EntityState.Modified;
                    }
                }
                log.Add("Forced password reset to '123456' for test users.");

                // --- NEW USERS (profesor2, estudiante2) ---

                // 2.1 Create profesor2 if not exists
                var prof2User = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == "profesor2");
                if (prof2User == null)
                {
                    var rolProf = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == "Profesor");
                    if (rolProf != null)
                    {
                        prof2User = new Usuario { NombreUsuario = "profesor2", ContrasenaHash = "123456", RolId = rolProf.IdRol };
                        _context.Usuarios.Add(prof2User);
                        await _context.SaveChangesAsync();
                        log.Add("Created user 'profesor2'");

                // 3. Seed New Roles for Test (Secretaria, Auditor, Seguridad, Coordinador)
                var demoUsers = new[] {
                    new { Role = "Secretaria",  User = "tester_sec",   Pass = "123456", CI = "V-11111111" },
                    new { Role = "Auditor",     User = "tester_aud",   Pass = "123456", CI = "V-22222222" },
                    new { Role = "Seguridad",   User = "tester_seg",   Pass = "123456", CI = "V-33333333" },
                    new { Role = "Coordinador", User = "tester_coord", Pass = "123456", CI = "V-44444444" }
                };

                foreach (var demo in demoUsers)
                {
                    if (!await _context.Usuarios.AnyAsync(u => u.NombreUsuario == demo.User))
                    {
                        var rol = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == demo.Role);
                        if (rol != null)
                        {
                            var u = new Usuario
                            {
                                NombreUsuario = demo.User,
                                ContrasenaHash = demo.Pass,
                                RolId = rol.IdRol,
                                Cedula = demo.CI,
                                EstadoCuenta = true,
                                Activo = true
                            };
                            _context.Usuarios.Add(u);
                            log.Add($"Created demo user '{demo.User}' with role {demo.Role}");
                        }
                    }
                }

                        // Create associated Professor entity
                        var newProf = new Profesor
                        {
                            Cedula = "V-22222222",
                            Nombres = "Maria Perez",
                            Apellidos = "Docente",
                            CorreoInstitucional = "maria@uptm.edu.ve",
                            Telefono = "0412-2222222",
                            UsuarioId = prof2User.IdUsuario
                        };
                        _context.Profesores.Add(newProf);
                        await _context.SaveChangesAsync();
                        log.Add("Created and linked Professor entity for 'profesor2'");
                    }
                }

                // 2.2 Create estudiante2 if not exists
                var est2User = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == "estudiante2");
                if (est2User == null)
                {
                    var rolEst = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == "Estudiante");
                    if (rolEst != null)
                    {
                        est2User = new Usuario { NombreUsuario = "estudiante2", ContrasenaHash = "123456", RolId = rolEst.IdRol };
                        _context.Usuarios.Add(est2User);
                        await _context.SaveChangesAsync();
                        log.Add("Created user 'estudiante2'");

                        // Create associated Student entity
                        var newEst = new Estudiante
                        {
                            Cedula = "V-33333333",
                            Nombres = "Carlos Ruiz",
                            Apellidos = "Alumno",
                            CorreoInstitucional = "carlos@uptm.edu.ve",
                            Direccion = "Centro",
                            UsuarioId = est2User.IdUsuario
                        };
                        _context.Estudiantes.Add(newEst);
                        await _context.SaveChangesAsync();
                        log.Add("Created and linked Student entity for 'estudiante2'");
                    }
                }

                // 2.3 Create seguridad1 if not exists
                var seg1User = await _context.Usuarios.FirstOrDefaultAsync(u => u.NombreUsuario == "seguridad1");
                if (seg1User == null)
                {
                    var rolSeg = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == "Seguridad");
                    if (rolSeg != null)
                    {
                        seg1User = new Usuario { NombreUsuario = "seguridad1", ContrasenaHash = "123456", RolId = rolSeg.IdRol, EstadoCuenta = true, UltimoAcceso = DateTime.Now };
                        _context.Usuarios.Add(seg1User);
                        await _context.SaveChangesAsync();
                        log.Add("Created user 'seguridad1'");
                    }
                }

                await _context.SaveChangesAsync();
                log.Add("Users verified/created.");

                // 3. Seed Content Data (Anuncios, Asignaturas, Inscripciones, Notas)

                // 3.1 Anuncios
                if (!await _context.Anuncios.AnyAsync())
                {
                    _context.Anuncios.AddRange(
                        new Anuncio { Titulo = "Bienvenida al Periodo 2025-I", Contenido = "Iniciamos actividades académicas con entusiasmo.", FechaPublicacion = DateTime.Now.AddDays(-5), Autor = "Rectorado" },
                        new Anuncio { Titulo = "Mantenimiento de Plataforma", Contenido = "El sistema estará en mantenimiento el domingo.", FechaPublicacion = DateTime.Now.AddDays(-2), Autor = "Soporte Técnico" },
                        new Anuncio { Titulo = "Feria de Proyectos", Contenido = "Inscripciones abiertas para la feria anual.", FechaPublicacion = DateTime.Now, Autor = "Coordinación" }
                    );
                    log.Add("Seeded 3 Anuncios.");
                }

                // 3.2 Asignaturas & Links
                var p1 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == "V-99999991");
                var p2 = await _context.Profesores.FirstOrDefaultAsync(p => p.Cedula == "V-22222222");
                var e1 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula == "V-15000000");
                var e2 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.Cedula == "V-33333333");

                if (p1 != null && p2 != null && e1 != null && e2 != null)
                {

                    // Tables should exist via EF Core Migrations or ensureCreated


                    // 3.2 Asignaturas (Expanded)
                    // Helper to create if not exists
                    async Task<Asignatura> EnsureAsignatura(string code, string name, int sem, int cred, int profId)
                    {
                        var a = await _context.Asignaturas.FirstOrDefaultAsync(x => x.Codigo == code);
                        if (a == null)
                        {
                            a = new Asignatura { Codigo = code, Nombre = name, Creditos = cred, Departamento = "General", ProfesorId = profId };
                            _context.Asignaturas.Add(a);
                        }
                        return a;
                    }

                    var asig1 = await EnsureAsignatura("MAT101", "Matematica I", 1, 3, p1.IdProfesor);
                    var asig2 = await EnsureAsignatura("PROG101", "Programacion I", 1, 4, p2.IdProfesor);
                    var asig3 = await EnsureAsignatura("BD201", "Base de Datos", 2, 3, p1.IdProfesor);
                    var asig4 = await EnsureAsignatura("ING101", "Ingles I", 1, 2, p2.IdProfesor);
                    var asig5 = await EnsureAsignatura("FIS101", "Fisica I", 1, 3, p1.IdProfesor);

                    await _context.SaveChangesAsync();
                    log.Add("Ensured Asignaturas (5 subjects) exist.");

                    // 3.3 Inscripciones (Expanded)
                    async Task EnsureInscripcion(int estId, int asigId)
                    {
                        if (!await _context.Inscripciones.AnyAsync(i => i.EstudianteId == estId && i.AsignaturaId == asigId))
                            _context.Inscripciones.Add(new Inscripcion { EstudianteId = estId, AsignaturaId = asigId,  FechaInscripcion = DateTime.Now, Estado = "Inscrito" });
                    }

                    // E1: All Sem 1
                    await EnsureInscripcion(e1.IdEstudiante, asig1.IdAsignatura);
                    await EnsureInscripcion(e1.IdEstudiante, asig2.IdAsignatura);
                    await EnsureInscripcion(e1.IdEstudiante, asig4.IdAsignatura);
                    await EnsureInscripcion(e1.IdEstudiante, asig5.IdAsignatura);

                    // E2: Mixed
                    await EnsureInscripcion(e2.IdEstudiante, asig1.IdAsignatura);
                    await EnsureInscripcion(e2.IdEstudiante, asig3.IdAsignatura); // BD is sem 2, advanced student

                    log.Add("Seeded/Verified Inscripciones.");

                    // 3.4 Notas (Expanded)
                    if (!await _context.Notas.AnyAsync())
                    {
                        _context.Notas.AddRange(
                           new Nota { EstudianteId = e1.IdEstudiante, AsignaturaId = asig1.IdAsignatura, Calificacion = 18, ProfesorId = p1.IdProfesor, CodigoQR = "QR-MAT-001", Fecha = DateTime.Now.AddDays(-10) },
                           new Nota { EstudianteId = e1.IdEstudiante, AsignaturaId = asig2.IdAsignatura, Calificacion = 16, ProfesorId = p2.IdProfesor, CodigoQR = "QR-PROG-001", Fecha = DateTime.Now.AddDays(-5) },
                           new Nota { EstudianteId = e2.IdEstudiante, AsignaturaId = asig3.IdAsignatura, Calificacion = 15, ProfesorId = p1.IdProfesor, CodigoQR = "QR-BD-001", Fecha = DateTime.Now.AddDays(-2) }
                       );
                        log.Add("Seeded initial Notas.");
                    }

                    // 3.5 Mensajes (Expanded)
                    if (!await _context.Mensajes.AnyAsync(m => m.AsignaturaId == asig2.IdAsignatura))
                    {
                        _context.Mensajes.AddRange(
                           new Mensaje { AsignaturaId = asig2.IdAsignatura, Contenido = "Bienvenidos al curso de Programación I", FechaEnvio = DateTime.Now.AddDays(-10), EmisorNombre = p2.Nombres + " " + p2.Apellidos },
                           new Mensaje { AsignaturaId = asig2.IdAsignatura, Contenido = "Recuerden instalar Visual Studio Code", FechaEnvio = DateTime.Now.AddDays(-8), EmisorNombre = p2.Nombres + " " + p2.Apellidos },
                           new Mensaje { AsignaturaId = asig2.IdAsignatura, Contenido = "¿Cuándo es el primer examen?", FechaEnvio = DateTime.Now.AddDays(-7), EmisorNombre = e1.Nombres + " " + e1.Apellidos }
                        );
                        log.Add("Seeded messages for PROG101.");
                    }

                    // 3.6 Horarios (Expanded)
                    if (!await _context.Horarios.AnyAsync())
                    {
                        _context.Horarios.AddRange(
                           new Horario { AsignaturaId = asig1.IdAsignatura, Dia = "Lunes", HoraInicio = "08:00", HoraFin = "10:00", Aula = "Lab 1" },
                           new Horario { AsignaturaId = asig1.IdAsignatura, Dia = "Miercoles", HoraInicio = "08:00", HoraFin = "10:00", Aula = "Aula 12" },
                           new Horario { AsignaturaId = asig2.IdAsignatura, Dia = "Martes", HoraInicio = "10:00", HoraFin = "12:00", Aula = "Lab 2" },
                           new Horario { AsignaturaId = asig2.IdAsignatura, Dia = "Jueves", HoraInicio = "10:00", HoraFin = "12:00", Aula = "Lab 2" },
                           new Horario { AsignaturaId = asig3.IdAsignatura, Dia = "Viernes", HoraInicio = "14:00", HoraFin = "16:00", Aula = "Aula 5" },
                           new Horario { AsignaturaId = asig4.IdAsignatura, Dia = "Lunes", HoraInicio = "14:00", HoraFin = "16:00", Aula = "Aula 3" },
                           new Horario { AsignaturaId = asig5.IdAsignatura, Dia = "Miercoles", HoraInicio = "10:00", HoraFin = "12:00", Aula = "Lab Fisica" }
                        );
                        log.Add("Seeded Schedules (Horarios) for all subjects.");
                    }

                    // 3.7 Asistencias (New)
                    if (!await _context.Asistencias.AnyAsync())
                    {
                        _context.Asistencias.AddRange(
                            new Asistencia { EstudianteId = e1.IdEstudiante, AsignaturaId = asig1.IdAsignatura, Fecha = DateTime.Now.AddDays(-7), Estado = "Presente" },
                            new Asistencia { EstudianteId = e1.IdEstudiante, AsignaturaId = asig1.IdAsignatura, Fecha = DateTime.Now.AddDays(-2), Estado = "Ausente" },
                            new Asistencia { EstudianteId = e1.IdEstudiante, AsignaturaId = asig2.IdAsignatura, Fecha = DateTime.Now.AddDays(-5), Estado = "Presente" }
                        );
                        log.Add("Seeded Asistencias.");
                    }

                    // 3.8 Constancias (New)
                    if (!await _context.Constancias.AnyAsync())
                    {
                        _context.Constancias.Add(
                            new Constancia { EstudianteId = e1.IdEstudiante, TipoConstancia = "Estudio", FechaSolicitud = DateTime.Now.AddMonths(-1), ArchivoUrl = "https://example.com/constancia1.pdf", Estado = "Emitida" }
                        );
                        log.Add("Seeded Constancias.");
                    }

                }

                // --- REGISTRO INSTITUCIONAL (MOCK) ---
                // Tables should exist via EF Core migrations

                if (!await _context.RegistrosInstitucionales.AnyAsync())
                {
                    _context.RegistrosInstitucionales.AddRange(
                        // Unregistered Students
                        new RegistroInstitucional { Cedula = "V-20000001", Nombres = "Diego", Apellidos = "Martinez", CarreraDepartamento = "Informatica", RolEsperado = "Estudiante", CorreoInstitucional = "diego@uptm.edu.ve" },
                        new RegistroInstitucional { Cedula = "V-20000002", Nombres = "Laura", Apellidos = "Sofia", CarreraDepartamento = "Administracion", RolEsperado = "Estudiante", CorreoInstitucional = "laura@uptm.edu.ve" },
                        // Unregistered Professor
                        new RegistroInstitucional { Cedula = "V-10000001", Nombres = "Roberto", Apellidos = "Gomez", CarreraDepartamento = "Matematica", RolEsperado = "Profesor", CorreoInstitucional = "roberto@uptm.edu.ve" },
                        // Unregistered Seguridad
                        new RegistroInstitucional { Cedula = "V-30000001", Nombres = "Carlos", Apellidos = "Guardia", CarreraDepartamento = "Vigilancia", RolEsperado = "Seguridad", CorreoInstitucional = "carlos.guardia@uptm.edu.ve" }
                    );
                    log.Add("Seeded RegistroInstitucional with 3 mock records.");
                }

                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                log.Add($"Data linking error: {ex.Message}");
            }

            return Ok(new { Message = "Setup completed", Log = log });
        }

        // ── SEED NOTIFICACIONES ──────────────────────────────────────────────────
        [HttpPost("seed-notificaciones")]
        public async Task<IActionResult> SeedNotificaciones()
        {
            var log = new List<string>();
            try
            {
                if (await _context.Notificaciones.AnyAsync())
                    return Ok(new { message = "Las notificaciones ya existen. Omitiendo.", log });

                var userMap = await _context.Usuarios.ToDictionaryAsync(u => u.NombreUsuario, u => u.IdUsuario);
                var now = DateTime.UtcNow;
                var notificaciones = new List<Notificacion>();

                foreach (var kvp in userMap)
                {
                    notificaciones.Add(new Notificacion { UsuarioId = kvp.Value, Titulo = "Bienvenido a UPTM Digital", Cuerpo = "Tu cuenta ha sido activada.", Tipo = "Sistema", Leida = true, FechaCreacion = now.AddDays(-30) });
                    notificaciones.Add(new Notificacion { UsuarioId = kvp.Value, Titulo = "Mantenimiento programado", Cuerpo = "Mantenimiento el sábado 15/03.", Tipo = "Sistema", Leida = false, FechaCreacion = now.AddDays(-5) });
                }

                var nots = new[] {
                    ("est_rodriguez", "Nueva nota publicada", "Nota de Informática: 18 pts.", "Academica", 20),
                    ("est_lopez",     "Nueva nota publicada", "Nota de Informática: 20 pts.", "Academica", 20),
                    ("prof_garcia",   "Nuevo mensaje en chat","Pregunta en INF101.",           "Chat",      1),
                };
                foreach (var (login, titulo, cuerpo, tipo, dias) in nots)
                    if (userMap.TryGetValue(login, out var uid))
                        notificaciones.Add(new Notificacion { UsuarioId = uid, Titulo = titulo, Cuerpo = cuerpo, Tipo = tipo, Leida = false, FechaCreacion = now.AddDays(-dias) });

                _context.Notificaciones.AddRange(notificaciones);
                await _context.SaveChangesAsync();
                log.Add($"Notificaciones: {notificaciones.Count} creadas.");
            }
            catch (Exception ex) { return StatusCode(500, new { step = "seed-notificaciones", error = ex.Message, log }); }
            return Ok(new { message = "Notificaciones sembradas.", log });
        }



        // ── SEED MENSAJES V2 (conversaciones realistas) ──────────────────────────
        [HttpPost("seed-mensajes-v2")]
        public async Task<IActionResult> SeedMensajesV2()
        {
            var log = new List<string>();
            try
            {
                if (await _context.Mensajes.AnyAsync())
                    return Ok(new { message = "Los mensajes ya existen. Omitiendo.", log });

                var inf101 = await _context.Asignaturas.FirstOrDefaultAsync(a => a.Codigo == "INF101");
                var prg101 = await _context.Asignaturas.FirstOrDefaultAsync(a => a.Codigo == "PRG101");
                var mat101 = await _context.Asignaturas.FirstOrDefaultAsync(a => a.Codigo == "MAT101");
                var adm101 = await _context.Asignaturas.FirstOrDefaultAsync(a => a.Codigo == "ADM101");

                if (inf101 == null || prg101 == null || mat101 == null || adm101 == null)
                    return BadRequest(new { message = "Ejecuta seed-academico primero.", log });

                var now = DateTime.UtcNow;
                var mensajes = new List<Mensaje>();

                // INF101 — Carlos García (prof) + Daniela & Andrés (est)
                var inf = inf101.IdAsignatura;
                mensajes.AddRange(new[]
                {
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Prof. Carlos García",    Contenido = "Bienvenidos a Introducción a la Informática. Por favor revisen el programa en el grupo.",           FechaEnvio = now.AddDays(-20) },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Daniela Rodríguez",      Contenido = "Profe, ¿cuándo es el primer corte?",                                                                  FechaEnvio = now.AddDays(-19) },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Prof. Carlos García",    Contenido = "El primer corte será el próximo viernes. Temas: historia de la informática y hardware.",              FechaEnvio = now.AddDays(-19) },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Andrés López",           Contenido = "¿Incluye la clase del martes pasado?",                                                                FechaEnvio = now.AddDays(-18) },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Prof. Carlos García",    Contenido = "Sí, hasta la clase de este miércoles inclusive.",                                                     FechaEnvio = now.AddDays(-18) },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Daniela Rodríguez",      Contenido = "¡Gracias profe! Nos preparamos.",                                                                     FechaEnvio = now.AddDays(-17) },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Prof. Carlos García",    Contenido = "Recuerden: la evaluación incluye parte práctica en el laboratorio.",                                  FechaEnvio = now.AddDays(-10) },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Andrés López",           Contenido = "Profe, ¿se puede usar apuntes en el examen práctico?",                                               FechaEnvio = now.AddDays(-9)  },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Prof. Carlos García",    Contenido = "No, es sin material. Pero es básico, no se preocupen.",                                              FechaEnvio = now.AddDays(-9)  },
                    new Mensaje { AsignaturaId = inf, EmisorNombre = "Daniela Rodríguez",      Contenido = "Ok profe, muchas gracias por avisar 🙏",                                                             FechaEnvio = now.AddDays(-8)  },
                });

                // PRG101 — Carlos García (prof) + múltiples estudiantes
                var prg = prg101.IdAsignatura;
                mensajes.AddRange(new[]
                {
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Prof. Carlos García",    Contenido = "En la clase de hoy vamos a ver pseudocódigo y diagramas de flujo. Traigan papel cuadriculado.",      FechaEnvio = now.AddDays(-14) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Andrés López",           Contenido = "Profe, ¿instalamos algo para la próxima clase?",                                                      FechaEnvio = now.AddDays(-13) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Prof. Carlos García",    Contenido = "Sí. Instalen Python 3.11 y VS Code. El enlace está en el aula virtual.",                             FechaEnvio = now.AddDays(-13) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Daniela Rodríguez",      Contenido = "¿La versión de Python importa? Yo tengo la 3.9.",                                                    FechaEnvio = now.AddDays(-12) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Prof. Carlos García",    Contenido = "Con 3.9 está bien, no hay problema.",                                                                 FechaEnvio = now.AddDays(-12) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "José Vargas",            Contenido = "Profe, me salió un error al instalar VS Code en Windows 7. ¿Qué hago?",                              FechaEnvio = now.AddDays(-11) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Prof. Carlos García",    Contenido = "VS Code no soporta Windows 7. Intenta con Notepad++ + Python directo en terminal por ahora.",        FechaEnvio = now.AddDays(-11) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "José Vargas",            Contenido = "¡Gracias profe, ya funcionó!",                                                                        FechaEnvio = now.AddDays(-10) },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Andrés López",           Contenido = "Profe, ¿el proyecto final es individual o en grupo?",                                                 FechaEnvio = now.AddDays(-5)  },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Prof. Carlos García",    Contenido = "En parejas. Les daré más detalles la próxima semana.",                                                FechaEnvio = now.AddDays(-5)  },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Daniela Rodríguez",      Contenido = "¿Puedo formar pareja con alguien de otra sección?",                                                   FechaEnvio = now.AddDays(-4)  },
                    new Mensaje { AsignaturaId = prg, EmisorNombre = "Prof. Carlos García",    Contenido = "Solo con alguien de esta misma sección, por favor.",                                                  FechaEnvio = now.AddDays(-4)  },
                });

                // MAT101 — María Mendoza (prof)
                var mat = mat101.IdAsignatura;
                mensajes.AddRange(new[]
                {
                    new Mensaje { AsignaturaId = mat, EmisorNombre = "Prof. María Mendoza",    Contenido = "Los ejercicios del capítulo 3 son para entregar el jueves. No olviden mostrar el procedimiento.",   FechaEnvio = now.AddDays(-7) },
                    new Mensaje { AsignaturaId = mat, EmisorNombre = "Daniela Rodríguez",      Contenido = "Profe, ¿los ejercicios pares o impares?",                                                            FechaEnvio = now.AddDays(-6) },
                    new Mensaje { AsignaturaId = mat, EmisorNombre = "Prof. María Mendoza",    Contenido = "Del 1 al 20, todos.",                                                                                 FechaEnvio = now.AddDays(-6) },
                    new Mensaje { AsignaturaId = mat, EmisorNombre = "Miguel Pérez",           Contenido = "¿Se puede entregar en digital o tiene que ser en físico?",                                           FechaEnvio = now.AddDays(-5) },
                    new Mensaje { AsignaturaId = mat, EmisorNombre = "Prof. María Mendoza",    Contenido = "Físico, escrito a mano. Muéstrenme el procedimiento paso a paso.",                                   FechaEnvio = now.AddDays(-5) },
                    new Mensaje { AsignaturaId = mat, EmisorNombre = "Valentina Fernández",    Contenido = "Profe, el ejercicio 15 no lo entiendo bien. ¿Puede explicarlo de nuevo?",                            FechaEnvio = now.AddDays(-2) },
                    new Mensaje { AsignaturaId = mat, EmisorNombre = "Prof. María Mendoza",    Contenido = "Claro, mañana empezamos con ese ejercicio antes de continuar con el tema nuevo.",                    FechaEnvio = now.AddDays(-2) },
                });

                // ADM101 — Ana Ramírez (prof)
                var adm = adm101.IdAsignatura;
                mensajes.AddRange(new[]
                {
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Prof. Ana Ramírez",      Contenido = "Para el miércoles deben leer los capítulos 1 y 2 del libro de Robbins. Hay discusión en clase.",    FechaEnvio = now.AddDays(-8) },
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Valentina Fernández",    Contenido = "¿Cuál edición del libro, profe?",                                                                    FechaEnvio = now.AddDays(-7) },
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Prof. Ana Ramírez",      Contenido = "Cualquier edición del 2011 en adelante sirve. Los conceptos son los mismos.",                       FechaEnvio = now.AddDays(-7) },
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Miguel Pérez",           Contenido = "Profe, ¿tiene el PDF del libro?",                                                                    FechaEnvio = now.AddDays(-6) },
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Prof. Ana Ramírez",      Contenido = "Lo subiré al grupo de WhatsApp esta tarde.",                                                         FechaEnvio = now.AddDays(-6) },
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Valentina Fernández",    Contenido = "¡Gracias profe! 🙏",                                                                                FechaEnvio = now.AddDays(-6) },
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Miguel Pérez",           Contenido = "¿La discusión es en grupos o individual?",                                                           FechaEnvio = now.AddDays(-1) },
                    new Mensaje { AsignaturaId = adm, EmisorNombre = "Prof. Ana Ramírez",      Contenido = "Grupal. Formaremos grupos de 3 en clase.",                                                           FechaEnvio = now.AddDays(-1) },
                });

                _context.Mensajes.AddRange(mensajes);
                await _context.SaveChangesAsync();
                log.Add($"Mensajes: {mensajes.Count} creados en 4 asignaturas.");
            }
            catch (Exception ex) { return StatusCode(500, new { step = "seed-mensajes-v2", error = ex.Message, log }); }
            return Ok(new { message = "✅ Mensajes realistas sembrados correctamente.", log });
        }

        // ── SEED ALL: Ejecuta todos los pasos en secuencia ───────────────────────
        [HttpPost("seed-all")]
        public async Task<IActionResult> SeedAll()
        {
            var log = new List<string>();
            try
            {
                // Paso 1: Base
                var r1 = await SeedBase() as OkObjectResult;
                if (r1 == null) return StatusCode(500, new { step = "seed-base", message = "seed-base falló.", log });
                log.Add("✅ Paso 1 (seed-base) completado.");

                // Paso 2: Académico
                var r2 = await SeedAcademico() as OkObjectResult;
                if (r2 == null) return StatusCode(500, new { step = "seed-academico", message = "seed-academico falló.", log });
                log.Add("✅ Paso 2 (seed-academico) completado.");

                // Paso 3: Extra
                var r3 = await SeedExtra() as OkObjectResult;
                if (r3 == null) return StatusCode(500, new { step = "seed-extra", message = "seed-extra falló.", log });
                log.Add("✅ Paso 3 (seed-extra) completado.");

                // Paso 4: Notificaciones
                var r4 = await SeedNotificaciones() as OkObjectResult;
                if (r4 == null) return StatusCode(500, new { step = "seed-notificaciones", message = "seed-notificaciones falló.", log });
                log.Add("✅ Paso 4 (seed-notificaciones) completado.");

                // Paso 5: Mensajes
                var r5 = await SeedMensajesV2() as OkObjectResult;
                if (r5 == null) return StatusCode(500, new { step = "seed-mensajes", message = "seed-mensajes falló.", log });
                log.Add("✅ Paso 5 (seed-mensajes) completado.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message, log });
            }

            return Ok(new
            {
                message = "🎓 ¡Base de datos completamente poblada para la mesa técnica!",
                credenciales_principales = new[]
                {
                    new { usuario = "tester_admin", pass = "123456", rol = "Administrador" },
                    new { usuario = "tester_prof",  pass = "123456", rol = "Profesor" },
                    new { usuario = "tester_est",   pass = "123456", rol = "Estudiante" },
                    new { usuario = "tester_seg",   pass = "123456", rol = "Seguridad" },
                    new { usuario = "tester_coord", pass = "123456", rol = "Coordinador" },
                    new { usuario = "tester_sec",   pass = "123456", rol = "Secretaria" },
                },
                credenciales_demo = new[]
                {
                    new { usuario = "prof_garcia",    pass = "123456", rol = "Profesor",    nombre = "Carlos García" },
                    new { usuario = "prof_mendoza",   pass = "123456", rol = "Profesor",    nombre = "María Mendoza" },
                    new { usuario = "prof_torres",    pass = "123456", rol = "Profesor",    nombre = "Luis Torres" },
                    new { usuario = "prof_ramirez",   pass = "123456", rol = "Profesor",    nombre = "Ana Ramírez" },
                    new { usuario = "est_rodriguez",  pass = "123456", rol = "Estudiante",  nombre = "Daniela Rodríguez" },
                    new { usuario = "est_lopez",      pass = "123456", rol = "Estudiante",  nombre = "Andrés López" },
                    new { usuario = "est_fernandez",  pass = "123456", rol = "Estudiante",  nombre = "Valentina Fernández" },
                    new { usuario = "est_perez",      pass = "123456", rol = "Estudiante",  nombre = "Miguel Pérez" },
                    new { usuario = "est_morales",    pass = "123456", rol = "Estudiante",  nombre = "Gabriela Morales" },
                    new { usuario = "est_vargas",     pass = "123456", rol = "Estudiante",  nombre = "José Vargas" },
                },
                log
            });
        }

        // ── STATUS: Resumen del estado actual de la BD (tolerante a tablas faltantes) ──
        [HttpGet("status")]
        public async Task<IActionResult> Status()
        {
            async Task<object> SafeCount(Func<Task<int>> fn, string tabla)
            {
                try { return (object)await fn(); }
                catch { return (object)$"❌ tabla '{tabla}' no existe"; }
            }

            var status = new Dictionary<string, object>
            {
                ["roles"]                    = await SafeCount(() => _context.Roles.CountAsync(),                    "Rol"),
                ["usuarios"]                 = await SafeCount(() => _context.Usuarios.CountAsync(),                 "Usuario"),
                ["profesores"]               = await SafeCount(() => _context.Profesores.CountAsync(),               "Profesor"),
                ["estudiantes"]              = await SafeCount(() => _context.Estudiantes.CountAsync(),              "Estudiante"),
                ["asignaturas"]              = await SafeCount(() => _context.Asignaturas.CountAsync(),              "Asignatura"),
                ["horarios"]                 = await SafeCount(() => _context.Horarios.CountAsync(),                 "Horarios"),
                ["inscripciones"]            = await SafeCount(() => _context.Inscripciones.CountAsync(),            "Inscripcion"),
                ["notas"]                    = await SafeCount(() => _context.Notas.CountAsync(),                    "Nota"),
                ["asistencias"]              = await SafeCount(() => _context.Asistencias.CountAsync(),              "Asistencia"),
                ["anuncios"]                 = await SafeCount(() => _context.Anuncios.CountAsync(),                 "Anuncio"),
                ["constancias"]              = await SafeCount(() => _context.Constancias.CountAsync(),              "Constancia"),
                ["notificaciones"]           = await SafeCount(() => _context.Notificaciones.CountAsync(),           "Notificacion"),
                ["mensajes"]                 = await SafeCount(() => _context.Mensajes.CountAsync(),                 "Mensaje"),
                ["controlAccesos"]           = await SafeCount(() => _context.ControlAccesos.CountAsync(),           "ControlAcceso"),
                ["registrosInstitucionales"] = await SafeCount(() => _context.RegistrosInstitucionales.CountAsync(), "RegistrosInstitucionales"),
                ["listo_para_demo"]          = (object)true
            };
            return Ok(status);
        }


        // ── CREATE MISSING TABLES: crea con DDL directo las tablas que faltan ────
        [HttpPost("create-missing-tables")]
        public async Task<IActionResult> CreateMissingTables()
        {
            var log = new List<string>();
            try
            {
                // Tabla Notificacion
                await _context.Database.ExecuteSqlRawAsync(@"
                    CREATE TABLE IF NOT EXISTS ""Notificacion"" (
                        ""IdNotificacion""  SERIAL       PRIMARY KEY,
                        ""UsuarioId""       INTEGER      NOT NULL REFERENCES ""Usuario""(""IdUsuario"") ON DELETE CASCADE,
                        ""Titulo""          TEXT         NOT NULL,
                        ""Cuerpo""          TEXT         NOT NULL,
                        ""Tipo""            TEXT         NOT NULL DEFAULT 'Sistema',
                        ""Leida""           BOOLEAN      NOT NULL DEFAULT false,
                        ""FechaCreacion""   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
                    );
                ");
                log.Add("✅ Tabla 'Notificacion' creada o ya existía.");

                // Registrar en __EFMigrationsHistory para que EF no intente recrearla
                await _context.Database.ExecuteSqlRawAsync(@"
                    INSERT INTO ""__EFMigrationsHistory""(""MigrationId"", ""ProductVersion"")
                    VALUES ('20260325235145_NotificacionesTable', '9.0.0')
                    ON CONFLICT DO NOTHING;
                ");
                log.Add("✅ Migración 'NotificacionesTable' marcada en historial.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { step = "create-missing-tables", error = ex.Message, log });
            }
            return Ok(new { message = "✅ Tablas faltantes creadas. Puedes llamar seed-notificaciones ahora.", log });
        }

        // ── FIX: Crear FK faltante Horarios → Asignatura ─────────────────────────
        [HttpPost("fix-horarios-fk")]
        public async Task<IActionResult> FixHorariosForeignKey()
        {
            var log = new List<string>();
            try
            {
                // 1. Crear el índice si no existe
                await _context.Database.ExecuteSqlRawAsync(@"
                    CREATE INDEX IF NOT EXISTS ""IX_Horarios_AsignaturaId""
                    ON ""Horarios"" (""AsignaturaId"");
                ");
                log.Add("Índice IX_Horarios_AsignaturaId verificado/creado.");

                // 2. Crear la FK si no existe (PostgreSQL no tiene IF NOT EXISTS para constraints)
                await _context.Database.ExecuteSqlRawAsync(@"
                    DO $$
                    BEGIN
                        IF NOT EXISTS (
                            SELECT 1 FROM information_schema.table_constraints
                            WHERE constraint_name = 'FK_Horarios_Asignatura_AsignaturaId'
                              AND table_name = 'Horarios'
                        ) THEN
                            ALTER TABLE ""Horarios""
                            ADD CONSTRAINT ""FK_Horarios_Asignatura_AsignaturaId""
                            FOREIGN KEY (""AsignaturaId"")
                            REFERENCES ""Asignatura"" (""IdAsignatura"")
                            ON DELETE CASCADE;
                        END IF;
                    END $$;
                ");
                log.Add("Foreign Key FK_Horarios_Asignatura_AsignaturaId verificada/creada.");

                // 3. Verificar que el constraint existe ahora
                var verification = await _context.Database
                    .SqlQueryRaw<string>(@"
                        SELECT constraint_name AS ""Value""
                        FROM information_schema.table_constraints
                        WHERE table_name = 'Horarios'
                          AND constraint_type = 'FOREIGN KEY'
                    ")
                    .ToListAsync();

                log.Add($"Constraints FK activos en Horarios: {string.Join(", ", verification)}");

                return Ok(new
                {
                    message = "✅ FK Horarios → Asignatura corregida exitosamente.",
                    log
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    step = "fix-horarios-fk",
                    error = ex.Message,
                    stack = ex.ToString(),
                    log
                });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════
        // NUKE AND RESEED — Borrado total y re-llenado con datos de prueba
        // Uso: POST /api/setup/nuke-and-reseed
        // ══════════════════════════════════════════════════════════════════════════
        [HttpPost("nuke-and-reseed")]
        public async Task<IActionResult> NukeAndReseed()
        {
            var log = new List<string>();
            var strategy = _context.Database.CreateExecutionStrategy();

            try
            {
                // ═══════════════════════════════════════════════════════
                // FASE 0: ASEGURAR ESQUEMA (RAW SQL — no depende de migraciones)
                // ═══════════════════════════════════════════════════════
                var schemaFixes = new[]
                {
                    "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Coordinador' AND column_name='Apellidos') THEN ALTER TABLE \"Coordinador\" ADD COLUMN \"Apellidos\" text; END IF; END $$;",
                    "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Coordinador' AND column_name='Nombres') THEN ALTER TABLE \"Coordinador\" ADD COLUMN \"Nombres\" text; END IF; END $$;",
                    "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Nota' AND column_name='EvaluacionId') THEN ALTER TABLE \"Nota\" ADD COLUMN \"EvaluacionId\" integer; END IF; END $$;",
                    "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Nota' AND column_name='ProfesorId') THEN ALTER TABLE \"Nota\" ADD COLUMN \"ProfesorId\" integer; END IF; END $$;",
                    "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='PinAsistencia' AND column_name='CarreraId') THEN ALTER TABLE \"PinAsistencia\" ADD COLUMN \"CarreraId\" integer; END IF; END $$;",
                    "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Mensaje' AND column_name='CarreraId') THEN ALTER TABLE \"Mensaje\" ADD COLUMN \"CarreraId\" integer; END IF; END $$;",
                    "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Anuncio' AND column_name='Trimestre') THEN ALTER TABLE \"Anuncio\" ADD COLUMN \"Trimestre\" text; END IF; END $$;",
                    "CREATE TABLE IF NOT EXISTS \"GlobalSetting\" (\"Clave\" text NOT NULL PRIMARY KEY, \"Valor\" text NOT NULL, \"UltimaActualizacion\" timestamp with time zone NOT NULL);",
                };
                foreach (var sql in schemaFixes)
                {
                    try { await _context.Database.ExecuteSqlRawAsync(sql); }
                    catch (Exception exSql) { log.Add($"⚠️ Schema fix: {exSql.Message}"); }
                }
                log.Add("✅ FASE 0: Esquema verificado/actualizado.");

                await strategy.ExecuteAsync(async () =>
                {
                    await using var tx = await _context.Database.BeginTransactionAsync();

                    // ═══════════════════════════════════════════════════════
                    // FASE 1: BORRADO TOTAL (TRUNCATE CASCADE)
                    // ═══════════════════════════════════════════════════════
                    var tables = new[]
                    {
                        "AuditLog", "ArancelValidacion", "EvaluacionConfig",
                        "PinAsistencia", "SolicitudApertura", "Notificacion",
                        "Mensaje", "ControlAcceso", "Constancia", "Nota",
                        "Asistencia", "Inscripcion", "Horarios", "Asignatura",
                        "Aula", "Coordinador", "Profesor", "Estudiante",
                        "Anuncio", "Usuario", "RegistroInstitucional",
                        "Rol", "Carrera", "Semestre", "Periodo"
                    };
                    foreach (var table in tables)
                    {
                        try
                        {
                            await _context.Database.ExecuteSqlRawAsync(
                                $"TRUNCATE TABLE \"{table}\" RESTART IDENTITY CASCADE;");
                        }
                        catch { /* tabla puede no existir aún */ }
                    }
                    // GlobalSetting puede no estar migrada
                    try { await _context.Database.ExecuteSqlRawAsync("TRUNCATE TABLE \"GlobalSetting\" RESTART IDENTITY CASCADE;"); } catch { }

                    log.Add("✅ FASE 1 COMPLETADA: Todas las tablas vaciadas.");

                    // ═══════════════════════════════════════════════════════
                    // FASE 2: SEED COMPLETO
                    // ═══════════════════════════════════════════════════════
                    var now = DateTime.UtcNow;

                    // ── 2.1 Roles ─────────────────────────────────────
                    var rolNames = new[] { "Administrador", "Profesor", "Estudiante", "Seguridad", "Coordinador", "Secretaria", "SuperAdmin", "Auditor" };
                    var roles = new Dictionary<string, Rol>();
                    foreach (var name in rolNames)
                    {
                        var r = new Rol { NombreRol = name };
                        _context.Roles.Add(r);
                        roles[name] = r;
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Roles: {roles.Count} creados.");

                    // ── 2.2 Carreras ──────────────────────────────────
                    var carreraNames = new[] { "Informática", "Administración", "Contaduría", "Turismo" };
                    var carreras = new Dictionary<string, Carrera>();
                    foreach (var name in carreraNames)
                    {
                        var c = new Carrera { Nombre = name };
                        _context.Carreras.Add(c);
                        carreras[name] = c;
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Carreras: {carreras.Count} creadas.");

                    // ── 2.3 Semestres ─────────────────────────────────
                    foreach (var name in new[] { "Trimestre I", "Trimestre II", "Trimestre III", "Trimestre IV", "Trimestre V", "Trimestre VI" })
                        _context.Semestres.Add(new Semestre { Nombre = name });
                    await _context.SaveChangesAsync();
                    log.Add("✅ Semestres: 6 creados.");

                    // ── 2.4 Periodos ──────────────────────────────────
                    var periodoActivo = new Periodo { Nombre = "2025-I", Activo = true };
                    _context.Periodos.AddRange(periodoActivo, new Periodo { Nombre = "2024-II", Activo = false });
                    await _context.SaveChangesAsync();
                    log.Add("✅ Periodos: 2 creados.");

                    // ── 2.5 Registros Institucionales (Nómina) ────────
                    var regData = new (string ced, string nom, string ape, string dep, string rol, string correo)[]
                    {
                        ("V-10000001", "Admin",     "Sistema",     "Rectorado",       "Administrador", "admin@uptm.edu.ve"),
                        ("V-10000002", "Super",     "Admin",       "Rectorado",       "SuperAdmin",    "superadmin@uptm.edu.ve"),
                        ("V-10000003", "Ana",       "Auditora",    "Auditoría",       "Auditor",       "auditor@uptm.edu.ve"),
                        ("V-12345678", "Carlos",    "García",      "Informática",     "Profesor",      "c.garcia@uptm.edu.ve"),
                        ("V-18765432", "María",     "Mendoza",     "Matemáticas",     "Profesor",      "m.mendoza@uptm.edu.ve"),
                        ("V-14523678", "Luis",      "Torres",      "Sistemas",        "Profesor",      "l.torres@uptm.edu.ve"),
                        ("V-20134576", "Ana",       "Ramírez",     "Administración",  "Profesor",      "a.ramirez@uptm.edu.ve"),
                        ("V-27112233", "Daniela",   "Rodríguez",   "Informática",     "Estudiante",    "d.rodriguez@uptm.edu.ve"),
                        ("V-28990011", "Andrés",    "López",       "Informática",     "Estudiante",    "a.lopez@uptm.edu.ve"),
                        ("V-29445566", "Valentina", "Fernández",   "Administración",  "Estudiante",    "v.fernandez@uptm.edu.ve"),
                        ("V-26778899", "Miguel",    "Pérez",       "Administración",  "Estudiante",    "m.perez@uptm.edu.ve"),
                        ("V-30123456", "Gabriela",  "Morales",     "Contaduría",      "Estudiante",    "g.morales@uptm.edu.ve"),
                        ("V-25667788", "José",      "Vargas",      "Informática",     "Estudiante",    "j.vargas@uptm.edu.ve"),
                        ("V-40000001", "Pedro",     "Guardia",     "Seguridad",       "Seguridad",     "p.guardia@uptm.edu.ve"),
                        ("V-50000001", "Roberto",   "Díaz",        "Informática",     "Coordinador",   "r.diaz@uptm.edu.ve"),
                        ("V-60000001", "Sofía",     "Martínez",    "Secretaría",      "Secretaria",    "s.martinez@uptm.edu.ve"),
                        // Pre-registrados SIN cuenta (para probar registro)
                        ("V-31500001", "Diego",     "Gutiérrez",   "Informática",     "Estudiante",    "d.gutierrez@uptm.edu.ve"),
                        ("V-32100002", "Laura",     "Acosta",      "Turismo",         "Estudiante",    "l.acosta@uptm.edu.ve"),
                        ("V-19876543", "Pedro",     "Núñez",       "Matemáticas",     "Profesor",      "p.nunez@uptm.edu.ve"),
                        ("V-45000001", "Marcos",    "Vigilante",   "Seguridad",       "Seguridad",     "m.vigilante@uptm.edu.ve"),
                    };
                    foreach (var (ced, nom, ape, dep, rol, correo) in regData)
                        _context.RegistrosInstitucionales.Add(new RegistroInstitucional
                        {
                            Cedula = ced, Nombres = nom, Apellidos = ape,
                            CarreraDepartamento = dep, RolEsperado = rol, CorreoInstitucional = correo
                        });
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Registros Institucionales: {regData.Length} creados.");

                    // ── 2.6 Usuarios ──────────────────────────────────
                    var userData = new (string user, string ced, string rolName)[]
                    {
                        ("admin",          "V-10000001", "Administrador"),
                        ("superadmin",     "V-10000002", "SuperAdmin"),
                        ("auditor1",       "V-10000003", "Auditor"),
                        ("prof_garcia",    "V-12345678", "Profesor"),
                        ("prof_mendoza",   "V-18765432", "Profesor"),
                        ("prof_torres",    "V-14523678", "Profesor"),
                        ("prof_ramirez",   "V-20134576", "Profesor"),
                        ("est_rodriguez",  "V-27112233", "Estudiante"),
                        ("est_lopez",      "V-28990011", "Estudiante"),
                        ("est_fernandez",  "V-29445566", "Estudiante"),
                        ("est_perez",      "V-26778899", "Estudiante"),
                        ("est_morales",    "V-30123456", "Estudiante"),
                        ("est_vargas",     "V-25667788", "Estudiante"),
                        ("seguridad1",     "V-40000001", "Seguridad"),
                        ("coordinador1",   "V-50000001", "Coordinador"),
                        ("secretaria1",    "V-60000001", "Secretaria"),
                    };
                    var usuarios = new Dictionary<string, Usuario>();
                    foreach (var (user, ced, rolName) in userData)
                    {
                        var ri = await _context.RegistrosInstitucionales
                            .FirstOrDefaultAsync(r => r.Cedula == ced);
                        var u = new Usuario
                        {
                            NombreUsuario = user,
                            ContrasenaHash = "123456",
                            Cedula = ced,
                            RolId = roles[rolName].IdRol,
                            EstadoCuenta = true,
                            Activo = true,
                            UltimoAcceso = now,
                            RegistroInstitucionalId = ri?.Id
                        };
                        _context.Usuarios.Add(u);
                        usuarios[user] = u;
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Usuarios: {usuarios.Count} creados.");

                    // ── 2.7 Profesores ─────────────────────────────────
                    var profData = new (string user, string ced, string nom, string ape, string correo, string dep, string cod, string tel)[]
                    {
                        ("prof_garcia",  "V-12345678", "Carlos", "García",  "c.garcia@uptm.edu.ve",  "Informática",    "P001", "0412-1234567"),
                        ("prof_mendoza", "V-18765432", "María",  "Mendoza", "m.mendoza@uptm.edu.ve", "Matemáticas",    "P002", "0416-7654321"),
                        ("prof_torres",  "V-14523678", "Luis",   "Torres",  "l.torres@uptm.edu.ve",  "Sistemas",       "P003", "0424-5236781"),
                        ("prof_ramirez", "V-20134576", "Ana",    "Ramírez", "a.ramirez@uptm.edu.ve", "Administración", "P004", "0426-3415762"),
                    };
                    var profesores = new Dictionary<string, Profesor>();
                    foreach (var (user, ced, nom, ape, correo, dep, cod, tel) in profData)
                    {
                        var p = new Profesor
                        {
                            Cedula = ced, Nombres = nom, Apellidos = ape,
                            CorreoInstitucional = correo, Departamento = dep,
                            CodProfesor = cod, Telefono = tel,
                            UsuarioId = usuarios[user].IdUsuario, Activo = true
                        };
                        _context.Profesores.Add(p);
                        profesores[user] = p;
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Profesores: {profesores.Count} creados.");

                    // ── 2.8 Estudiantes ────────────────────────────────
                    var estData = new (string user, string ced, string nom, string ape, string correo, string carrera, string cod, string dir, string tel)[]
                    {
                        ("est_rodriguez", "V-27112233", "Daniela",   "Rodríguez", "d.rodriguez@uptm.edu.ve", "Informática",    "20230001", "Av. Principal, Mérida",    "0412-9988776"),
                        ("est_lopez",     "V-28990011", "Andrés",    "López",     "a.lopez@uptm.edu.ve",     "Informática",    "20230002", "Urb. La Floresta, Mérida", "0416-1122334"),
                        ("est_fernandez", "V-29445566", "Valentina", "Fernández", "v.fernandez@uptm.edu.ve", "Administración", "20230003", "Bella Vista, Mérida",      "0424-5566778"),
                        ("est_perez",     "V-26778899", "Miguel",    "Pérez",     "m.perez@uptm.edu.ve",     "Administración", "20230004", "Res. Los Pinos, Mérida",   "0426-7788990"),
                        ("est_morales",   "V-30123456", "Gabriela",  "Morales",   "g.morales@uptm.edu.ve",   "Contaduría",     "20230005", "Calle 3, El Vigía",        "0412-3344556"),
                        ("est_vargas",    "V-25667788", "José",      "Vargas",    "j.vargas@uptm.edu.ve",    "Informática",    "20220010", "Edif. Las Palmas, Mérida", "0416-6677889"),
                    };
                    var estudiantes = new Dictionary<string, Estudiante>();
                    foreach (var (user, ced, nom, ape, correo, carreraN, cod, dir, tel) in estData)
                    {
                        var e = new Estudiante
                        {
                            Cedula = ced, Nombres = nom, Apellidos = ape,
                            CorreoInstitucional = correo, CodAlumno = cod,
                            Direccion = dir, Telefono = tel,
                            UsuarioId = usuarios[user].IdUsuario,
                            CarreraId = carreras[carreraN].IdCarrera,
                            FechaRegistro = now.AddDays(-90),
                            Activo = true, EstadoArancel = true
                        };
                        _context.Estudiantes.Add(e);
                        estudiantes[user] = e;
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Estudiantes: {estudiantes.Count} creados.");

                    // ── 2.9 Coordinadores ──────────────────────────────
                    _context.Coordinadores.Add(new Coordinador
                    {
                        UsuarioId = usuarios["coordinador1"].IdUsuario,
                        Nombres = "Roberto", Apellidos = "Díaz",
                        CarreraId = carreras["Informática"].IdCarrera,
                        Activo = true
                    });
                    await _context.SaveChangesAsync();
                    log.Add("✅ Coordinadores: 1 creado.");

                    // ── 2.10 Aulas ─────────────────────────────────────
                    var aulasData = new (string nom, string edif, string piso, string estado)[]
                    {
                        ("Lab Computación 1", "Bloque A", "Piso 1", "Disponible"),
                        ("Lab Computación 2", "Bloque A", "Piso 1", "Disponible"),
                        ("Lab Redes",         "Bloque A", "Piso 2", "Disponible"),
                        ("Lab Física",        "Bloque B", "Piso 1", "Mantenimiento"),
                        ("Aula 01",           "Bloque C", "Piso 1", "Disponible"),
                        ("Aula 02",           "Bloque C", "Piso 1", "Disponible"),
                        ("Aula 05",           "Bloque C", "Piso 2", "Disponible"),
                        ("Aula 08",           "Bloque D", "Piso 1", "Disponible"),
                    };
                    var aulas = new Dictionary<string, Aula>();
                    foreach (var (nom, edif, piso, estado) in aulasData)
                    {
                        var a = new Aula { Nombre = nom, Edificio = edif, Piso = piso, Estado = estado, Activo = true };
                        _context.Aulas.Add(a);
                        aulas[nom] = a;
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Aulas: {aulas.Count} creadas.");

                    // ── 2.11 Asignaturas ───────────────────────────────
                    var p1 = profesores["prof_garcia"];
                    var p2 = profesores["prof_mendoza"];
                    var p3 = profesores["prof_torres"];
                    var p4 = profesores["prof_ramirez"];

                    var asigData = new (string cod, string nom, int cred, string dep, int profId, int? carreraId)[]
                    {
                        ("INF101", "Introducción a la Informática",   3, "Informática",    p1.IdProfesor, carreras["Informática"].IdCarrera),
                        ("PRG101", "Algoritmos y Programación I",     4, "Informática",    p1.IdProfesor, carreras["Informática"].IdCarrera),
                        ("PRG201", "Programación Orientada a Objetos",4, "Informática",    p3.IdProfesor, carreras["Informática"].IdCarrera),
                        ("BD201",  "Base de Datos I",                 3, "Informática",    p3.IdProfesor, carreras["Informática"].IdCarrera),
                        ("MAT101", "Cálculo I",                       4, "Matemáticas",    p2.IdProfesor, carreras["Informática"].IdCarrera),
                        ("ADM101", "Principios de Administración",    3, "Administración", p4.IdProfesor, carreras["Administración"].IdCarrera),
                        ("ADM201", "Contabilidad General",            3, "Administración", p4.IdProfesor, carreras["Administración"].IdCarrera),
                        ("ING101", "Inglés Técnico I",                2, "Idiomas",        p2.IdProfesor, null),
                        ("SIS301", "Redes y Comunicaciones",          3, "Sistemas",       p3.IdProfesor, carreras["Informática"].IdCarrera),
                    };
                    var asignaturas = new Dictionary<string, Asignatura>();
                    foreach (var (cod, nom, cred, dep, profId, carreraId) in asigData)
                    {
                        var a = new Asignatura
                        {
                            Codigo = cod, Nombre = nom, Creditos = cred,
                            Departamento = dep, ProfesorId = profId,
                            CarreraId = carreraId, Activo = true
                        };
                        _context.Asignaturas.Add(a);
                        asignaturas[cod] = a;
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Asignaturas: {asignaturas.Count} creadas.");

                    // Shortcuts estudiantes
                    var e1 = estudiantes["est_rodriguez"];
                    var e2 = estudiantes["est_lopez"];
                    var e3 = estudiantes["est_fernandez"];
                    var e4 = estudiantes["est_perez"];
                    var e5 = estudiantes["est_morales"];
                    var e6 = estudiantes["est_vargas"];

                    // ── 2.12 Horarios ──────────────────────────────────
                    _context.Horarios.AddRange(
                        new Horario { AsignaturaId = asignaturas["INF101"].IdAsignatura, Dia = "Lunes",     HoraInicio = "07:00", HoraFin = "09:00", Aula = "Aula 01" },
                        new Horario { AsignaturaId = asignaturas["INF101"].IdAsignatura, Dia = "Miércoles", HoraInicio = "07:00", HoraFin = "09:00", Aula = "Aula 01" },
                        new Horario { AsignaturaId = asignaturas["PRG101"].IdAsignatura, Dia = "Lunes",     HoraInicio = "09:00", HoraFin = "11:00", Aula = "Lab Computación 1" },
                        new Horario { AsignaturaId = asignaturas["PRG101"].IdAsignatura, Dia = "Viernes",   HoraInicio = "09:00", HoraFin = "11:00", Aula = "Lab Computación 1" },
                        new Horario { AsignaturaId = asignaturas["PRG201"].IdAsignatura, Dia = "Martes",    HoraInicio = "11:00", HoraFin = "13:00", Aula = "Lab Computación 2" },
                        new Horario { AsignaturaId = asignaturas["PRG201"].IdAsignatura, Dia = "Jueves",    HoraInicio = "11:00", HoraFin = "13:00", Aula = "Lab Computación 2" },
                        new Horario { AsignaturaId = asignaturas["BD201"].IdAsignatura,  Dia = "Miércoles", HoraInicio = "14:00", HoraFin = "16:00", Aula = "Lab Computación 1" },
                        new Horario { AsignaturaId = asignaturas["MAT101"].IdAsignatura, Dia = "Martes",    HoraInicio = "07:00", HoraFin = "09:00", Aula = "Aula 05" },
                        new Horario { AsignaturaId = asignaturas["MAT101"].IdAsignatura, Dia = "Jueves",    HoraInicio = "07:00", HoraFin = "09:00", Aula = "Aula 05" },
                        new Horario { AsignaturaId = asignaturas["ADM101"].IdAsignatura, Dia = "Miércoles", HoraInicio = "13:00", HoraFin = "15:00", Aula = "Aula 08" },
                        new Horario { AsignaturaId = asignaturas["ADM201"].IdAsignatura, Dia = "Viernes",   HoraInicio = "13:00", HoraFin = "15:00", Aula = "Aula 08" },
                        new Horario { AsignaturaId = asignaturas["ING101"].IdAsignatura, Dia = "Jueves",    HoraInicio = "15:00", HoraFin = "17:00", Aula = "Aula 02" },
                        new Horario { AsignaturaId = asignaturas["SIS301"].IdAsignatura, Dia = "Viernes",   HoraInicio = "11:00", HoraFin = "13:00", Aula = "Lab Redes" }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ Horarios: 13 creados.");

                    // ── 2.13 Inscripciones ─────────────────────────────
                    var inscData = new (Estudiante est, string cod)[]
                    {
                        (e1,"INF101"),(e1,"PRG101"),(e1,"MAT101"),(e1,"ING101"),
                        (e2,"INF101"),(e2,"PRG101"),(e2,"PRG201"),
                        (e3,"ADM101"),(e3,"ADM201"),(e3,"MAT101"),
                        (e4,"ADM101"),(e4,"ING101"),
                        (e5,"ADM201"),(e5,"MAT101"),
                        (e6,"PRG201"),(e6,"BD201"),(e6,"SIS301"),
                    };
                    foreach (var (est, cod) in inscData)
                        _context.Inscripciones.Add(new Inscripcion
                        {
                            EstudianteId = est.IdEstudiante,
                            AsignaturaId = asignaturas[cod].IdAsignatura,
                            PeriodoId = periodoActivo.IdPeriodo,
                            FechaInscripcion = now.AddDays(-60),
                            Estado = "Activo"
                        });
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Inscripciones: {inscData.Length} creadas.");

                    // ── 2.14 Notas ─────────────────────────────────────
                    _context.Notas.AddRange(
                        new Nota { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["INF101"].IdAsignatura, ProfesorId=p1.IdProfesor, Calificacion=18, Fecha=now.AddDays(-20), CodigoQR="QR-INF101-001" },
                        new Nota { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["PRG101"].IdAsignatura, ProfesorId=p1.IdProfesor, Calificacion=16, Fecha=now.AddDays(-15), CodigoQR="QR-PRG101-001" },
                        new Nota { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["MAT101"].IdAsignatura, ProfesorId=p2.IdProfesor, Calificacion=14, Fecha=now.AddDays(-10), CodigoQR="QR-MAT101-001" },
                        new Nota { EstudianteId=e2.IdEstudiante, AsignaturaId=asignaturas["INF101"].IdAsignatura, ProfesorId=p1.IdProfesor, Calificacion=20, Fecha=now.AddDays(-20), CodigoQR="QR-INF101-002" },
                        new Nota { EstudianteId=e2.IdEstudiante, AsignaturaId=asignaturas["PRG101"].IdAsignatura, ProfesorId=p1.IdProfesor, Calificacion=15, Fecha=now.AddDays(-15), CodigoQR="QR-PRG101-002" },
                        new Nota { EstudianteId=e2.IdEstudiante, AsignaturaId=asignaturas["PRG201"].IdAsignatura, ProfesorId=p3.IdProfesor, Calificacion=17, Fecha=now.AddDays(-8),  CodigoQR="QR-PRG201-001" },
                        new Nota { EstudianteId=e3.IdEstudiante, AsignaturaId=asignaturas["ADM101"].IdAsignatura, ProfesorId=p4.IdProfesor, Calificacion=19, Fecha=now.AddDays(-12), CodigoQR="QR-ADM101-001" },
                        new Nota { EstudianteId=e4.IdEstudiante, AsignaturaId=asignaturas["ADM101"].IdAsignatura, ProfesorId=p4.IdProfesor, Calificacion=13, Fecha=now.AddDays(-12), CodigoQR="QR-ADM101-002" },
                        new Nota { EstudianteId=e5.IdEstudiante, AsignaturaId=asignaturas["ADM201"].IdAsignatura, ProfesorId=p4.IdProfesor, Calificacion=11, Fecha=now.AddDays(-5),  CodigoQR="QR-ADM201-001" },
                        new Nota { EstudianteId=e6.IdEstudiante, AsignaturaId=asignaturas["PRG201"].IdAsignatura, ProfesorId=p3.IdProfesor, Calificacion=18, Fecha=now.AddDays(-8),  CodigoQR="QR-PRG201-002" }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ Notas: 10 creadas.");

                    // ── 2.15 Asistencias ───────────────────────────────
                    _context.Asistencias.AddRange(
                        new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["INF101"].IdAsignatura, Fecha=now.AddDays(-21), Estado="Presente",     ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["INF101"].IdAsignatura, Fecha=now.AddDays(-14), Estado="Presente",     ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["INF101"].IdAsignatura, Fecha=now.AddDays(-7),  Estado="Ausente",      ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["PRG101"].IdAsignatura, Fecha=now.AddDays(-14), Estado="Presente",     ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=asignaturas["PRG101"].IdAsignatura, Fecha=now.AddDays(-7),  Estado="Presente",     ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e2.IdEstudiante, AsignaturaId=asignaturas["INF101"].IdAsignatura, Fecha=now.AddDays(-14), Estado="Presente",     ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e2.IdEstudiante, AsignaturaId=asignaturas["INF101"].IdAsignatura, Fecha=now.AddDays(-7),  Estado="Presente",     ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e2.IdEstudiante, AsignaturaId=asignaturas["PRG101"].IdAsignatura, Fecha=now.AddDays(-7),  Estado="Justificado",  ProfesorId=p1.IdProfesor },
                        new Asistencia { EstudianteId=e3.IdEstudiante, AsignaturaId=asignaturas["ADM101"].IdAsignatura, Fecha=now.AddDays(-14), Estado="Presente",     ProfesorId=p4.IdProfesor },
                        new Asistencia { EstudianteId=e3.IdEstudiante, AsignaturaId=asignaturas["ADM101"].IdAsignatura, Fecha=now.AddDays(-7),  Estado="Ausente",      ProfesorId=p4.IdProfesor },
                        new Asistencia { EstudianteId=e4.IdEstudiante, AsignaturaId=asignaturas["ADM101"].IdAsignatura, Fecha=now.AddDays(-7),  Estado="Presente",     ProfesorId=p4.IdProfesor },
                        new Asistencia { EstudianteId=e6.IdEstudiante, AsignaturaId=asignaturas["PRG201"].IdAsignatura, Fecha=now.AddDays(-7),  Estado="Presente",     ProfesorId=p3.IdProfesor }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ Asistencias: 12 creadas.");

                    // ── 2.16 Anuncios ──────────────────────────────────
                    var adminUid = usuarios["admin"].IdUsuario;
                    _context.Anuncios.AddRange(
                        new Anuncio { Titulo="Bienvenida al Período Académico 2025-I", Contenido="La UPTM Mérida da la bienvenida a toda la comunidad universitaria al inicio del período 2025-I. ¡Éxito!", FechaPublicacion=now.AddDays(-30), Autor="Rectorado", UsuarioId=adminUid, Prioridad="Normal", Activo=true },
                        new Anuncio { Titulo="Inicio de Inscripciones — Período 2025-II", Contenido="Las inscripciones para el período 2025-II estarán disponibles del 15 al 30 de junio.", FechaPublicacion=now.AddDays(-10), Autor="Coordinación Académica", UsuarioId=adminUid, Prioridad="Urgente", Activo=true },
                        new Anuncio { Titulo="Mantenimiento del Sistema", Contenido="El sistema estará en mantenimiento el sábado de 8:00am a 12:00pm.", FechaPublicacion=now.AddDays(-5), Autor="Soporte Técnico", UsuarioId=adminUid, Prioridad="Critica", Activo=true },
                        new Anuncio { Titulo="Feria de Proyectos Tecnológicos", Contenido="IV Feria de Proyectos Tecnológicos el 25 de abril en el patio principal. ¡Inscríbanse!", FechaPublicacion=now.AddDays(-2), Autor="Coordinación de Investigación", UsuarioId=adminUid, CarreraId=carreras["Informática"].IdCarrera, Prioridad="Normal", Activo=true },
                        new Anuncio { Titulo="Actualización de Notas — Primer Corte", Contenido="Los profesores deben registrar el primer corte antes del 20 del mes.", FechaPublicacion=now.AddDays(-1), Autor="Coordinación Docente", UsuarioId=adminUid, RolId=roles["Profesor"].IdRol, Prioridad="Urgente", Activo=true }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ Anuncios: 5 creados.");

                    // ── 2.17 Mensajes (Conversaciones por asignatura) ──
                    var uGarcia=usuarios["prof_garcia"]; var uMendoza=usuarios["prof_mendoza"];
                    var uRamirez=usuarios["prof_ramirez"];
                    var uDaniela=usuarios["est_rodriguez"]; var uAndres=usuarios["est_lopez"];
                    var uValentina=usuarios["est_fernandez"]; var uMiguel=usuarios["est_perez"];
                    var uJose=usuarios["est_vargas"];

                    var mensajes = new List<Mensaje>();
                    var inf=asignaturas["INF101"].IdAsignatura;
                    mensajes.AddRange(new[] {
                        new Mensaje { AsignaturaId=inf, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="Bienvenidos a Introducción a la Informática. Revisen el programa.",       FechaEnvio=now.AddDays(-20), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=inf, UsuarioId=uDaniela.IdUsuario, EmisorNombre="Daniela Rodríguez",    Contenido="Profe, ¿cuándo es el primer corte?",                                     FechaEnvio=now.AddDays(-19), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=inf, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="El primer corte será el próximo viernes. Temas: historia y hardware.",    FechaEnvio=now.AddDays(-19), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=inf, UsuarioId=uAndres.IdUsuario,  EmisorNombre="Andrés López",         Contenido="¿Incluye la clase del martes pasado?",                                   FechaEnvio=now.AddDays(-18), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=inf, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="Sí, hasta la clase de este miércoles inclusive.",                         FechaEnvio=now.AddDays(-18), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=inf, UsuarioId=uDaniela.IdUsuario, EmisorNombre="Daniela Rodríguez",    Contenido="¡Gracias profe! Nos preparamos.",                                         FechaEnvio=now.AddDays(-17), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=inf, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="Recuerden: la evaluación incluye parte práctica en el laboratorio.",      FechaEnvio=now.AddDays(-10), TipoChat="Asignatura" },
                    });

                    var prg=asignaturas["PRG101"].IdAsignatura;
                    mensajes.AddRange(new[] {
                        new Mensaje { AsignaturaId=prg, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="Hoy vemos pseudocódigo y diagramas de flujo. Traigan papel cuadriculado.", FechaEnvio=now.AddDays(-14), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uAndres.IdUsuario,  EmisorNombre="Andrés López",         Contenido="Profe, ¿instalamos algo para la próxima clase?",                          FechaEnvio=now.AddDays(-13), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="Sí. Instalen Python 3.11 y VS Code.",                                     FechaEnvio=now.AddDays(-13), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uDaniela.IdUsuario, EmisorNombre="Daniela Rodríguez",    Contenido="¿La versión de Python importa? Yo tengo la 3.9.",                          FechaEnvio=now.AddDays(-12), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="Con 3.9 está bien, no hay problema.",                                     FechaEnvio=now.AddDays(-12), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uJose.IdUsuario,    EmisorNombre="José Vargas",          Contenido="Profe, me salió un error al instalar VS Code en Windows 7.",               FechaEnvio=now.AddDays(-11), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="VS Code no soporta Windows 7. Intenta con Notepad++ por ahora.",           FechaEnvio=now.AddDays(-11), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uAndres.IdUsuario,  EmisorNombre="Andrés López",         Contenido="Profe, ¿el proyecto final es individual o en grupo?",                     FechaEnvio=now.AddDays(-5),  TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=prg, UsuarioId=uGarcia.IdUsuario,  EmisorNombre="Prof. Carlos García",  Contenido="En parejas. Les daré más detalles la próxima semana.",                     FechaEnvio=now.AddDays(-5),  TipoChat="Asignatura" },
                    });

                    var mat=asignaturas["MAT101"].IdAsignatura;
                    mensajes.AddRange(new[] {
                        new Mensaje { AsignaturaId=mat, UsuarioId=uMendoza.IdUsuario, EmisorNombre="Prof. María Mendoza",  Contenido="Los ejercicios del capítulo 3 son para entregar el jueves.",              FechaEnvio=now.AddDays(-7), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=mat, UsuarioId=uDaniela.IdUsuario, EmisorNombre="Daniela Rodríguez",    Contenido="Profe, ¿los ejercicios pares o impares?",                                 FechaEnvio=now.AddDays(-6), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=mat, UsuarioId=uMendoza.IdUsuario, EmisorNombre="Prof. María Mendoza",  Contenido="Del 1 al 20, todos.",                                                     FechaEnvio=now.AddDays(-6), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=mat, UsuarioId=uMiguel.IdUsuario,  EmisorNombre="Miguel Pérez",         Contenido="¿Se puede entregar en digital?",                                          FechaEnvio=now.AddDays(-5), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=mat, UsuarioId=uMendoza.IdUsuario, EmisorNombre="Prof. María Mendoza",  Contenido="Físico, escrito a mano. Muéstrenme el procedimiento.",                     FechaEnvio=now.AddDays(-5), TipoChat="Asignatura" },
                    });

                    var adm=asignaturas["ADM101"].IdAsignatura;
                    mensajes.AddRange(new[] {
                        new Mensaje { AsignaturaId=adm, UsuarioId=uRamirez.IdUsuario,  EmisorNombre="Prof. Ana Ramírez",    Contenido="Para el miércoles lean capítulos 1 y 2 del libro de Robbins.",           FechaEnvio=now.AddDays(-8), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=adm, UsuarioId=uValentina.IdUsuario, EmisorNombre="Valentina Fernández",  Contenido="¿Cuál edición del libro, profe?",                                        FechaEnvio=now.AddDays(-7), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=adm, UsuarioId=uRamirez.IdUsuario,  EmisorNombre="Prof. Ana Ramírez",    Contenido="Cualquier edición del 2011 en adelante sirve.",                            FechaEnvio=now.AddDays(-7), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=adm, UsuarioId=uMiguel.IdUsuario,   EmisorNombre="Miguel Pérez",         Contenido="Profe, ¿tiene el PDF del libro?",                                         FechaEnvio=now.AddDays(-6), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=adm, UsuarioId=uRamirez.IdUsuario,  EmisorNombre="Prof. Ana Ramírez",    Contenido="Lo subiré al grupo de WhatsApp esta tarde.",                               FechaEnvio=now.AddDays(-6), TipoChat="Asignatura" },
                        new Mensaje { AsignaturaId=adm, UsuarioId=uValentina.IdUsuario, EmisorNombre="Valentina Fernández",  Contenido="¡Gracias profe! 🙏",                                                     FechaEnvio=now.AddDays(-6), TipoChat="Asignatura" },
                    });
                    _context.Mensajes.AddRange(mensajes);
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Mensajes: {mensajes.Count} creados en 4 asignaturas.");

                    // ── 2.18 Constancias ───────────────────────────────
                    _context.Constancias.AddRange(
                        new Constancia { EstudianteId=e1.IdEstudiante, TipoConstancia="Estudio",        FechaSolicitud=now.AddDays(-20), Estado="Emitida",    CodigoQR="CONST-001" },
                        new Constancia { EstudianteId=e1.IdEstudiante, TipoConstancia="Buena Conducta", FechaSolicitud=now.AddDays(-10), Estado="Emitida",    CodigoQR="CONST-002" },
                        new Constancia { EstudianteId=e2.IdEstudiante, TipoConstancia="Notas",          FechaSolicitud=now.AddDays(-5),  Estado="En proceso", CodigoQR="CONST-003" },
                        new Constancia { EstudianteId=e3.IdEstudiante, TipoConstancia="Estudio",        FechaSolicitud=now.AddDays(-3),  Estado="Pendiente",  CodigoQR="CONST-004" }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ Constancias: 4 creadas.");

                    // ── 2.19 Control de Acceso ─────────────────────────
                    var segUid = usuarios["seguridad1"].IdUsuario;
                    _context.ControlAccesos.AddRange(
                        new ControlAcceso { Cedula="V-27112233", UsuarioId=uDaniela.IdUsuario,  PersonalSeguridadId=segUid, Tipo="Entrada", Ubicacion="Bloque A",            FechaHora=now.AddDays(-2).AddHours(7) },
                        new ControlAcceso { Cedula="V-27112233", UsuarioId=uDaniela.IdUsuario,  PersonalSeguridadId=segUid, Tipo="Salida",  Ubicacion="Bloque A",            FechaHora=now.AddDays(-2).AddHours(12) },
                        new ControlAcceso { Cedula="V-28990011", UsuarioId=uAndres.IdUsuario,   PersonalSeguridadId=segUid, Tipo="Entrada", Ubicacion="Bloque B",            FechaHora=now.AddDays(-2).AddHours(8) },
                        new ControlAcceso { Cedula="V-28990011", UsuarioId=uAndres.IdUsuario,   PersonalSeguridadId=segUid, Tipo="Salida",  Ubicacion="Bloque B",            FechaHora=now.AddDays(-2).AddHours(13) },
                        new ControlAcceso { Cedula="V-12345678", UsuarioId=uGarcia.IdUsuario,   PersonalSeguridadId=segUid, Tipo="Entrada", Ubicacion="Bloque C — Docentes", FechaHora=now.AddDays(-1).AddHours(7) },
                        new ControlAcceso { Cedula="V-12345678", UsuarioId=uGarcia.IdUsuario,   PersonalSeguridadId=segUid, Tipo="Salida",  Ubicacion="Bloque C — Docentes", FechaHora=now.AddDays(-1).AddHours(15) },
                        new ControlAcceso { Cedula="V-29445566", UsuarioId=uValentina.IdUsuario,PersonalSeguridadId=segUid, Tipo="Entrada", Ubicacion="Bloque A",            FechaHora=now.AddDays(-1).AddHours(9) },
                        new ControlAcceso { Cedula="V-26778899", UsuarioId=uMiguel.IdUsuario,   PersonalSeguridadId=segUid, Tipo="Entrada", Ubicacion="Bloque D",            FechaHora=now.AddHours(-3) }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ ControlAcceso: 8 registros creados.");

                    // ── 2.20 Notificaciones ────────────────────────────
                    var notificaciones = new List<Notificacion>();
                    foreach (var u in usuarios.Values)
                    {
                        notificaciones.Add(new Notificacion { UsuarioId=u.IdUsuario, Titulo="Bienvenido a UPTM Digital",  Cuerpo="Tu cuenta ha sido activada exitosamente.", Tipo="Sistema",   Leida=true,  FechaCreacion=now.AddDays(-30) });
                        notificaciones.Add(new Notificacion { UsuarioId=u.IdUsuario, Titulo="Mantenimiento programado",   Cuerpo="El sistema estará en mantenimiento el sábado.", Tipo="Sistema", Leida=false, FechaCreacion=now.AddDays(-5) });
                    }
                    notificaciones.Add(new Notificacion { UsuarioId=uDaniela.IdUsuario, Titulo="Nueva nota publicada",  Cuerpo="Tu nota de INF101: 18 pts.", Tipo="Academica", Leida=false, FechaCreacion=now.AddDays(-20) });
                    notificaciones.Add(new Notificacion { UsuarioId=uAndres.IdUsuario,  Titulo="Nueva nota publicada",  Cuerpo="Tu nota de INF101: 20 pts.", Tipo="Academica", Leida=false, FechaCreacion=now.AddDays(-20) });
                    notificaciones.Add(new Notificacion { UsuarioId=uGarcia.IdUsuario,  Titulo="Nuevo mensaje en chat", Cuerpo="Pregunta en INF101.",        Tipo="Chat",      Leida=false, FechaCreacion=now.AddDays(-1) });
                    notificaciones.Add(new Notificacion { UsuarioId=uDaniela.IdUsuario, Titulo="Constancia emitida",    Cuerpo="Tu constancia de estudio está lista.", Tipo="Sistema", Leida=false, FechaCreacion=now.AddDays(-18) });
                    _context.Notificaciones.AddRange(notificaciones);
                    await _context.SaveChangesAsync();
                    log.Add($"✅ Notificaciones: {notificaciones.Count} creadas.");

                    // ── 2.21 Evaluaciones Config ───────────────────────
                    _context.EvaluacionesConfig.AddRange(
                        new EvaluacionConfig { AsignaturaId=asignaturas["INF101"].IdAsignatura, Nombre="Examen Parcial 1",  Ponderacion=30, FechaEvaluacion=now.AddDays(-15), Activo=true },
                        new EvaluacionConfig { AsignaturaId=asignaturas["INF101"].IdAsignatura, Nombre="Proyecto Final",    Ponderacion=40, FechaEvaluacion=now.AddDays(20),  Activo=true },
                        new EvaluacionConfig { AsignaturaId=asignaturas["INF101"].IdAsignatura, Nombre="Participación",     Ponderacion=30, FechaEvaluacion=now.AddDays(30),  Activo=true },
                        new EvaluacionConfig { AsignaturaId=asignaturas["PRG101"].IdAsignatura, Nombre="Examen Práctico 1", Ponderacion=25, FechaEvaluacion=now.AddDays(-10), Activo=true },
                        new EvaluacionConfig { AsignaturaId=asignaturas["PRG101"].IdAsignatura, Nombre="Proyecto en Parejas",Ponderacion=50, FechaEvaluacion=now.AddDays(25), Activo=true },
                        new EvaluacionConfig { AsignaturaId=asignaturas["PRG101"].IdAsignatura, Nombre="Quices",            Ponderacion=25, FechaEvaluacion=now.AddDays(30),  Activo=true }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ EvaluacionesConfig: 6 creadas.");

                    // ── 2.22 Pines de Asistencia ───────────────────────
                    var coordUid = usuarios["coordinador1"].IdUsuario;
                    _context.PinesAsistencia.AddRange(
                        new PinAsistencia { Pin="ABC123", FechaExpiracion=now.AddDays(1),  CoordinadorId=coordUid, Activo=true },
                        new PinAsistencia { Pin="XYZ789", FechaExpiracion=now.AddDays(-1), CoordinadorId=coordUid, Activo=false }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ PinesAsistencia: 2 creados.");

                    // ── 2.23 Solicitudes de Apertura ───────────────────
                    _context.SolicitudApertura.AddRange(
                        new SolicitudApertura { AulaId=aulas["Lab Computación 1"].IdAula, ProfesorId=p1.IdProfesor, PersonalSeguridadId=segUid, FechaSolicitud=now.AddDays(-3), FechaAtencion=now.AddDays(-3).AddMinutes(10), FechaCompletada=now.AddDays(-3).AddMinutes(15), Estado="Completada", Motivo="Clase de Programación I" },
                        new SolicitudApertura { AulaId=aulas["Lab Redes"].IdAula, ProfesorId=p3.IdProfesor, FechaSolicitud=now.AddHours(-2), Estado="Pendiente", Motivo="Práctica de Redes" }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ SolicitudesApertura: 2 creadas.");

                    // ── 2.24 Global Settings (puede no existir) ────────
                    try
                    {
                        _context.GlobalSettings.AddRange(
                            new GlobalSetting { Clave="HabilitarSubidaNotas",   Valor="true",   UltimaActualizacion=now },
                            new GlobalSetting { Clave="HabilitarInscripciones", Valor="true",   UltimaActualizacion=now },
                            new GlobalSetting { Clave="PeriodoActual",          Valor="2025-I", UltimaActualizacion=now }
                        );
                        await _context.SaveChangesAsync();
                        log.Add("✅ GlobalSettings: 3 creados.");
                    }
                    catch { log.Add("⚠️ GlobalSettings omitido (tabla no migrada)."); }

                    // ── 2.25 Audit Logs ────────────────────────────────
                    _context.AuditLogs.AddRange(
                        new AuditLog { UsuarioId=adminUid,            Accion="POST", Ruta="/api/setup/nuke-and-reseed", IP="127.0.0.1",    Fecha=now, Detalles="Borrado y re-seed de base de datos." },
                        new AuditLog { UsuarioId=uGarcia.IdUsuario,   Accion="POST", Ruta="/api/notas",                IP="192.168.1.10",  Fecha=now.AddDays(-20), Detalles="Cargó notas de INF101." },
                        new AuditLog { UsuarioId=uDaniela.IdUsuario,  Accion="POST", Ruta="/api/constancias",          IP="192.168.1.25",  Fecha=now.AddDays(-20), Detalles="Solicitó constancia de estudio." },
                        new AuditLog { UsuarioId=segUid,              Accion="POST", Ruta="/api/controlacceso",        IP="10.0.0.5",      Fecha=now.AddDays(-2),  Detalles="Registró entrada de estudiante." },
                        new AuditLog { UsuarioId=coordUid,            Accion="POST", Ruta="/api/asistencias/generar-pin",IP="192.168.1.50", Fecha=now.AddDays(-1),  Detalles="Generó PIN de asistencia." }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ AuditLogs: 5 creados.");

                    // ── 2.26 Arancel Validación ────────────────────────
                    var secUid = usuarios["secretaria1"].IdUsuario;
                    _context.ArancelesValidaciones.AddRange(
                        new ArancelValidacion { CedulaEstudiante="V-27112233", NumeroFactura="FAC-2025-0001", FechaValidacion=now.AddDays(-25), SecretariaId=secUid, MetodoPago="Transferencia" },
                        new ArancelValidacion { CedulaEstudiante="V-28990011", NumeroFactura="FAC-2025-0002", FechaValidacion=now.AddDays(-20), SecretariaId=secUid, MetodoPago="Pago Móvil" },
                        new ArancelValidacion { CedulaEstudiante="V-29445566", NumeroFactura="FAC-2025-0003", FechaValidacion=now.AddDays(-15), SecretariaId=secUid, MetodoPago="Efectivo" }
                    );
                    await _context.SaveChangesAsync();
                    log.Add("✅ ArancelValidacion: 3 creados.");

                    log.Add("═══ FASE 2 COMPLETADA: Todos los datos sembrados ═══");
                    await tx.CommitAsync();
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message, stack = ex.ToString(), log });
            }

            return Ok(new
            {
                message = "🎓 ¡Base de datos completamente borrada y re-llenada con datos de prueba!",
                credenciales = new[]
                {
                    new { usuario = "admin",         password = "123456", rol = "Administrador",  nombre = "Admin Sistema" },
                    new { usuario = "superadmin",    password = "123456", rol = "SuperAdmin",     nombre = "Super Admin" },
                    new { usuario = "auditor1",      password = "123456", rol = "Auditor",        nombre = "Ana Auditora" },
                    new { usuario = "prof_garcia",   password = "123456", rol = "Profesor",       nombre = "Carlos García" },
                    new { usuario = "prof_mendoza",  password = "123456", rol = "Profesor",       nombre = "María Mendoza" },
                    new { usuario = "prof_torres",   password = "123456", rol = "Profesor",       nombre = "Luis Torres" },
                    new { usuario = "prof_ramirez",  password = "123456", rol = "Profesor",       nombre = "Ana Ramírez" },
                    new { usuario = "est_rodriguez", password = "123456", rol = "Estudiante",     nombre = "Daniela Rodríguez" },
                    new { usuario = "est_lopez",     password = "123456", rol = "Estudiante",     nombre = "Andrés López" },
                    new { usuario = "est_fernandez", password = "123456", rol = "Estudiante",     nombre = "Valentina Fernández" },
                    new { usuario = "est_perez",     password = "123456", rol = "Estudiante",     nombre = "Miguel Pérez" },
                    new { usuario = "est_morales",   password = "123456", rol = "Estudiante",     nombre = "Gabriela Morales" },
                    new { usuario = "est_vargas",    password = "123456", rol = "Estudiante",     nombre = "José Vargas" },
                    new { usuario = "seguridad1",    password = "123456", rol = "Seguridad",      nombre = "Pedro Guardia" },
                    new { usuario = "coordinador1",  password = "123456", rol = "Coordinador",    nombre = "Roberto Díaz" },
                    new { usuario = "secretaria1",   password = "123456", rol = "Secretaria",     nombre = "Sofía Martínez" },
                },
                registro_sin_cuenta = new[]
                {
                    new { cedula = "V-31500001", nombre = "Diego Gutiérrez",  rol = "Estudiante", nota = "Puede registrarse desde la app" },
                    new { cedula = "V-32100002", nombre = "Laura Acosta",     rol = "Estudiante", nota = "Puede registrarse desde la app" },
                    new { cedula = "V-19876543", nombre = "Pedro Núñez",      rol = "Profesor",   nota = "Puede registrarse desde la app" },
                    new { cedula = "V-45000001", nombre = "Marcos Vigilante",  rol = "Seguridad",  nota = "Puede registrarse desde la app" },
                },
                resumen = new
                {
                    roles = 8, carreras = 4, semestres = 6, periodos = 2,
                    registros_institucionales = 20, usuarios = 16,
                    profesores = 4, estudiantes = 6, coordinadores = 1,
                    aulas = 8, asignaturas = 9, horarios = 13,
                    inscripciones = 17, notas = 10, asistencias = 12,
                    anuncios = 5, mensajes = 27, constancias = 4,
                    control_accesos = 8, evaluaciones_config = 6,
                    pines_asistencia = 2, solicitudes_apertura = 2,
                    audit_logs = 5, arancel_validacion = 3
                },
                log
            });
        }
    }
}
