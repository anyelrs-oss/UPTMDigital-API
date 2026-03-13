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

                    await EnsureUserWithRoleAsync("tester_admin", "123456", "Administrador", log);
                    await EnsureUserWithRoleAsync("tester_seg", "123456", "Seguridad", log);
                    await EnsureUserWithRoleAsync("tester_prof", "123456", "Profesor", log);
                    await EnsureUserWithRoleAsync("tester_est", "123456", "Estudiante", log);

                    await EnsureProfesorProfileAsync("tester_prof", log);
                    await EnsureEstudianteProfileAsync("tester_est", log);

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
                    new { username = "tester_seg", password = "123456", role = "Seguridad" },
                    new { username = "tester_prof", password = "123456", role = "Profesor" },
                    new { username = "tester_est", password = "123456", role = "Estudiante" }
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
            var profile = await _context.Profesores.FirstOrDefaultAsync(p => p.UsuarioLogin == username);
            if (profile != null)
            {
                return;
            }

            _context.Profesores.Add(new Profesor
            {
                Cedula = "V-44444444",
                Nombres = "Test",
                Apellidos = "Profesor",
                CorreoInstitucional = "tester.prof@uptm.edu.ve",
                Departamento = "Informatica",
                Telefono = "0412-4444444",
                UsuarioLogin = username
            });
            log.Add($"Created professor profile linked to '{username}'.");
        }

        private async Task EnsureEstudianteProfileAsync(string username, List<string> log)
        {
            var profile = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioLogin == username);
            if (profile != null)
            {
                return;
            }

            _context.Estudiantes.Add(new Estudiante
            {
                Cedula = "V-55555555",
                Nombres = "Test",
                Apellidos = "Estudiante",
                CorreoInstitucional = "tester.est@uptm.edu.ve",
                Carrera = "Informatica",
                Direccion = "Merida",
                Telefono = "0412-5555555",
                FechaRegistro = DateTime.UtcNow,
                UsuarioLogin = username
            });
            log.Add($"Created student profile linked to '{username}'.");
        }

        [HttpPost("seed-full-data")]
        public async Task<IActionResult> SeedFullData()
        {
            var log = new List<string>();
            try
            {
                    // ── 1. ROLES ─────────────────────────────────────────────────────────
                    foreach (var r in new[] { "Administrador", "Profesor", "Estudiante", "Seguridad" })
                        if (!await _context.Roles.AnyAsync(x => x.NombreRol == r))
                        { _context.Roles.Add(new Rol { NombreRol = r }); }
                    await _context.SaveChangesAsync();

                    var rolProf = await _context.Roles.FirstAsync(r => r.NombreRol == "Profesor");
                    var rolEst  = await _context.Roles.FirstAsync(r => r.NombreRol == "Estudiante");
                    var rolAdm  = await _context.Roles.FirstAsync(r => r.NombreRol == "Administrador");
                    var rolSeg  = await _context.Roles.FirstAsync(r => r.NombreRol == "Seguridad");

                    // ── 2. PROFESORES ─────────────────────────────────────────────────────
                    var profData = new[]
                    {
                        new { Login="prof_garcia",    Pass="123456", Cedula="V-12345678", Nombres="Carlos",    Apellidos="García",    Correo="c.garcia@uptm.edu.ve",    Depto="Informática",  Cod="P001", Tel="0412-1234567" },
                        new { Login="prof_mendoza",   Pass="123456", Cedula="V-18765432", Nombres="María",     Apellidos="Mendoza",  Correo="m.mendoza@uptm.edu.ve",   Depto="Matemáticas",  Cod="P002", Tel="0416-7654321" },
                        new { Login="prof_torres",    Pass="123456", Cedula="V-14523678", Nombres="Luis",      Apellidos="Torres",   Correo="l.torres@uptm.edu.ve",    Depto="Sistemas",     Cod="P003", Tel="0424-5236781" },
                        new { Login="prof_ramirez",   Pass="123456", Cedula="V-20134576", Nombres="Ana",       Apellidos="Ramírez",  Correo="a.ramirez@uptm.edu.ve",   Depto="Ingeniería",   Cod="P004", Tel="0426-3415762" },
                    };
                    foreach (var p in profData)
                    {
                        if (!await _context.Usuarios.AnyAsync(u => u.NombreUsuario == p.Login))
                            _context.Usuarios.Add(new Usuario { NombreUsuario=p.Login, ContrasenaHash=p.Pass, RolId=rolProf.IdRol, EstadoCuenta=true, UltimoAcceso=DateTime.UtcNow });
                        if (!await _context.Profesores.AnyAsync(x => x.Cedula == p.Cedula))
                            _context.Profesores.Add(new Profesor { Cedula=p.Cedula, Nombres=p.Nombres, Apellidos=p.Apellidos, CorreoInstitucional=p.Correo, Departamento=p.Depto, CodProfesor=p.Cod, Telefono=p.Tel, UsuarioLogin=p.Login });
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"Profesores: {profData.Length} asegurados.");

                    var dbProfs = await _context.Profesores.ToListAsync();
                    var p1 = dbProfs.First(p => p.UsuarioLogin == "prof_garcia");
                    var p2 = dbProfs.First(p => p.UsuarioLogin == "prof_mendoza");
                    var p3 = dbProfs.First(p => p.UsuarioLogin == "prof_torres");
                    var p4 = dbProfs.First(p => p.UsuarioLogin == "prof_ramirez");

                    // ── 3. ESTUDIANTES ────────────────────────────────────────────────────
                    var estData = new[]
                    {
                        new { Login="est_rodriguez", Pass="123456", Cedula="V-27112233", Nombres="Daniela",   Apellidos="Rodríguez", Correo="d.rodriguez@uptm.edu.ve", Carrera="Informática",        CodAlumno="20230001", Dir="Av. Principal, Mérida",     Tel="0412-9988776" },
                        new { Login="est_lopez",      Pass="123456", Cedula="V-28990011", Nombres="Andrés",    Apellidos="López",     Correo="a.lopez@uptm.edu.ve",     Carrera="Informática",        CodAlumno="20230002", Dir="Urb. La Floresta, Mérida",Tel="0416-1122334" },
                        new { Login="est_fernandez",  Pass="123456", Cedula="V-29445566", Nombres="Valentina", Apellidos="Fernández", Correo="v.fernandez@uptm.edu.ve",  Carrera="Administración",     CodAlumno="20230003", Dir="Sector Bella Vista, Mérida",Tel="0424-5566778" },
                        new { Login="est_perez",      Pass="123456", Cedula="V-26778899", Nombres="Miguel",    Apellidos="Pérez",     Correo="m.perez@uptm.edu.ve",     Carrera="Administración",     CodAlumno="20230004", Dir="Res. Los Pinos, Mérida",  Tel="0426-7788990" },
                        new { Login="est_morales",    Pass="123456", Cedula="V-30123456", Nombres="Gabriela",  Apellidos="Morales",   Correo="g.morales@uptm.edu.ve",   Carrera="Contaduría",         CodAlumno="20230005", Dir="Calle 3, El Vigía",       Tel="0412-3344556" },
                        new { Login="est_vargas",     Pass="123456", Cedula="V-25667788", Nombres="José",      Apellidos="Vargas",    Correo="j.vargas@uptm.edu.ve",    Carrera="Informática",        CodAlumno="20220010", Dir="Edif. Las Palmas, Mérida",Tel="0416-6677889" },
                        new { Login="est_castillo",   Pass="123456", Cedula="V-31002233", Nombres="Laura",     Apellidos="Castillo",  Correo="l.castillo@uptm.edu.ve",  Carrera="Turismo",            CodAlumno="20230006", Dir="Av. Bolívar, Mérida",     Tel="0424-0011223" },
                        new { Login="est_jimenez",    Pass="123456", Cedula="V-24556677", Nombres="Carlos",    Apellidos="Jiménez",   Correo="c.jimenez@uptm.edu.ve",   Carrera="Contaduría",         CodAlumno="20210015", Dir="Urb. Milla, Mérida",      Tel="0426-5566770" },
                    };
                    foreach (var e in estData)
                    {
                        if (!await _context.Usuarios.AnyAsync(u => u.NombreUsuario == e.Login))
                            _context.Usuarios.Add(new Usuario { NombreUsuario=e.Login, ContrasenaHash=e.Pass, RolId=rolEst.IdRol, EstadoCuenta=true, UltimoAcceso=DateTime.UtcNow });
                        if (!await _context.Estudiantes.AnyAsync(x => x.Cedula == e.Cedula))
                            _context.Estudiantes.Add(new Estudiante { Cedula=e.Cedula, Nombres=e.Nombres, Apellidos=e.Apellidos, CorreoInstitucional=e.Correo, Carrera=e.Carrera, CodAlumno=e.CodAlumno, Direccion=e.Dir, Telefono=e.Tel, FechaRegistro=DateTime.UtcNow, UsuarioLogin=e.Login });
                    }
                    await _context.SaveChangesAsync();
                    log.Add($"Estudiantes: {estData.Length} asegurados.");

                    var dbEsts = await _context.Estudiantes.ToListAsync();
                    var e1 = dbEsts.First(e => e.UsuarioLogin == "est_rodriguez");
                    var e2 = dbEsts.First(e => e.UsuarioLogin == "est_lopez");
                    var e3 = dbEsts.First(e => e.UsuarioLogin == "est_fernandez");
                    var e4 = dbEsts.First(e => e.UsuarioLogin == "est_perez");
                    var e5 = dbEsts.First(e => e.UsuarioLogin == "est_morales");
                    var e6 = dbEsts.First(e => e.UsuarioLogin == "est_vargas");

                    // ── 4. ASIGNATURAS ────────────────────────────────────────────────────
                    async Task<Asignatura> EnsureAsig(string cod, string nom, int cred, int sem, string depto, int profId)
                    {
                        var a = await _context.Asignaturas.FirstOrDefaultAsync(x => x.Codigo == cod);
                        if (a == null) { a = new Asignatura { Codigo=cod, Nombre=nom, Creditos=cred, Semestre=sem, Departamento=depto, ProfesorId=profId }; _context.Asignaturas.Add(a); }
                        return a;
                    }
                    var a1  = await EnsureAsig("INF101", "Introducción a la Informática",   3, 1, "Informática",   p1.IdProfesor);
                    var a2  = await EnsureAsig("PRG101", "Algoritmos y Programación I",       4, 1, "Informática",   p1.IdProfesor);
                    var a3  = await EnsureAsig("PRG201", "Programación Orientada a Objetos",  4, 2, "Informática",   p3.IdProfesor);
                    var a4  = await EnsureAsig("BD201",  "Base de Datos I",                   3, 3, "Informática",   p3.IdProfesor);
                    var a5  = await EnsureAsig("MAT101", "Cálculo I",                         4, 1, "Matemáticas",   p2.IdProfesor);
                    var a6  = await EnsureAsig("MAT201", "Cálculo II",                        4, 2, "Matemáticas",   p2.IdProfesor);
                    var a7  = await EnsureAsig("ADM101", "Principios de Administración",      3, 1, "Administración",p4.IdProfesor);
                    var a8  = await EnsureAsig("ADM201", "Contabilidad General",              3, 2, "Administración",p4.IdProfesor);
                    var a9  = await EnsureAsig("ING101", "Inglés Técnico I",                  2, 1, "Idiomas",       p2.IdProfesor);
                    var a10 = await EnsureAsig("SIS301", "Redes y Comunicaciones",            3, 4, "Sistemas",      p3.IdProfesor);
                    await _context.SaveChangesAsync();
                    log.Add("Asignaturas: 10 aseguradas.");

                    // ── 5. HORARIOS ───────────────────────────────────────────────────────
                    if (!await _context.Horarios.AnyAsync())
                    {
                        _context.Horarios.AddRange(
                            new Horario { AsignaturaId=a1.IdAsignatura,  Dia="Lunes",    HoraInicio="07:00", HoraFin="09:00", Aula="Aula 01" },
                            new Horario { AsignaturaId=a1.IdAsignatura,  Dia="Miércoles",HoraInicio="07:00", HoraFin="09:00", Aula="Aula 01" },
                            new Horario { AsignaturaId=a2.IdAsignatura,  Dia="Lunes",    HoraInicio="09:00", HoraFin="11:00", Aula="Lab Computación" },
                            new Horario { AsignaturaId=a2.IdAsignatura,  Dia="Viernes",  HoraInicio="09:00", HoraFin="11:00", Aula="Lab Computación" },
                            new Horario { AsignaturaId=a3.IdAsignatura,  Dia="Martes",   HoraInicio="11:00", HoraFin="13:00", Aula="Lab Computación" },
                            new Horario { AsignaturaId=a5.IdAsignatura,  Dia="Martes",   HoraInicio="07:00", HoraFin="09:00", Aula="Aula 05" },
                            new Horario { AsignaturaId=a5.IdAsignatura,  Dia="Jueves",   HoraInicio="07:00", HoraFin="09:00", Aula="Aula 05" },
                            new Horario { AsignaturaId=a7.IdAsignatura,  Dia="Miércoles",HoraInicio="13:00", HoraFin="15:00", Aula="Aula 08" },
                            new Horario { AsignaturaId=a9.IdAsignatura,  Dia="Jueves",   HoraInicio="15:00", HoraFin="17:00", Aula="Aula 02" },
                            new Horario { AsignaturaId=a10.IdAsignatura, Dia="Viernes",  HoraInicio="11:00", HoraFin="13:00", Aula="Lab Redes" }
                        );
                        await _context.SaveChangesAsync();
                        log.Add("Horarios: 10 creados.");
                    }

                    // ── 6. INSCRIPCIONES ──────────────────────────────────────────────────
                    async Task EnsureInsc(int estId, int asigId)
                    {
                        if (!await _context.Inscripciones.AnyAsync(i => i.EstudianteId == estId && i.AsignaturaId == asigId))
                            _context.Inscripciones.Add(new Inscripcion { EstudianteId=estId, AsignaturaId=asigId, Periodo="2025-I", FechaInscripcion=DateTime.UtcNow, Estado="Activo" });
                    }
                    // Estudiantes de Informática
                    await EnsureInsc(e1.IdEstudiante, a1.IdAsignatura);
                    await EnsureInsc(e1.IdEstudiante, a2.IdAsignatura);
                    await EnsureInsc(e1.IdEstudiante, a5.IdAsignatura);
                    await EnsureInsc(e1.IdEstudiante, a9.IdAsignatura);
                    await EnsureInsc(e2.IdEstudiante, a1.IdAsignatura);
                    await EnsureInsc(e2.IdEstudiante, a2.IdAsignatura);
                    await EnsureInsc(e2.IdEstudiante, a3.IdAsignatura);
                    await EnsureInsc(e6.IdEstudiante, a3.IdAsignatura);
                    await EnsureInsc(e6.IdEstudiante, a4.IdAsignatura);
                    await EnsureInsc(e6.IdEstudiante, a10.IdAsignatura);
                    // Estudiantes de Administración
                    await EnsureInsc(e3.IdEstudiante, a7.IdAsignatura);
                    await EnsureInsc(e3.IdEstudiante, a8.IdAsignatura);
                    await EnsureInsc(e3.IdEstudiante, a5.IdAsignatura);
                    await EnsureInsc(e4.IdEstudiante, a7.IdAsignatura);
                    await EnsureInsc(e4.IdEstudiante, a9.IdAsignatura);
                    // Contaduría
                    await EnsureInsc(e5.IdEstudiante, a8.IdAsignatura);
                    await EnsureInsc(e5.IdEstudiante, a5.IdAsignatura);
                    await _context.SaveChangesAsync();
                    log.Add("Inscripciones: 17 aseguradas.");

                    // ── 7. NOTAS ──────────────────────────────────────────────────────────
                    if (!await _context.Notas.AnyAsync())
                    {
                        _context.Notas.AddRange(
                            new Nota { EstudianteId=e1.IdEstudiante, AsignaturaId=a1.IdAsignatura,  ProfesorId=p1.IdProfesor, Calificacion=18, Fecha=DateTime.UtcNow.AddDays(-20), CodigoQR="QR-INF101-001" },
                            new Nota { EstudianteId=e1.IdEstudiante, AsignaturaId=a2.IdAsignatura,  ProfesorId=p1.IdProfesor, Calificacion=16, Fecha=DateTime.UtcNow.AddDays(-15), CodigoQR="QR-PRG101-001" },
                            new Nota { EstudianteId=e1.IdEstudiante, AsignaturaId=a5.IdAsignatura,  ProfesorId=p2.IdProfesor, Calificacion=14, Fecha=DateTime.UtcNow.AddDays(-10), CodigoQR="QR-MAT101-001" },
                            new Nota { EstudianteId=e2.IdEstudiante, AsignaturaId=a1.IdAsignatura,  ProfesorId=p1.IdProfesor, Calificacion=20, Fecha=DateTime.UtcNow.AddDays(-20), CodigoQR="QR-INF101-002" },
                            new Nota { EstudianteId=e2.IdEstudiante, AsignaturaId=a2.IdAsignatura,  ProfesorId=p1.IdProfesor, Calificacion=15, Fecha=DateTime.UtcNow.AddDays(-15), CodigoQR="QR-PRG101-002" },
                            new Nota { EstudianteId=e2.IdEstudiante, AsignaturaId=a3.IdAsignatura,  ProfesorId=p3.IdProfesor, Calificacion=17, Fecha=DateTime.UtcNow.AddDays(-8),  CodigoQR="QR-PRG201-001" },
                            new Nota { EstudianteId=e3.IdEstudiante, AsignaturaId=a7.IdAsignatura,  ProfesorId=p4.IdProfesor, Calificacion=19, Fecha=DateTime.UtcNow.AddDays(-12), CodigoQR="QR-ADM101-001" },
                            new Nota { EstudianteId=e3.IdEstudiante, AsignaturaId=a5.IdAsignatura,  ProfesorId=p2.IdProfesor, Calificacion=12, Fecha=DateTime.UtcNow.AddDays(-6),  CodigoQR="QR-MAT101-003" },
                            new Nota { EstudianteId=e4.IdEstudiante, AsignaturaId=a7.IdAsignatura,  ProfesorId=p4.IdProfesor, Calificacion=13, Fecha=DateTime.UtcNow.AddDays(-12), CodigoQR="QR-ADM101-002" },
                            new Nota { EstudianteId=e5.IdEstudiante, AsignaturaId=a8.IdAsignatura,  ProfesorId=p4.IdProfesor, Calificacion=11, Fecha=DateTime.UtcNow.AddDays(-5),  CodigoQR="QR-ADM201-001" },
                            new Nota { EstudianteId=e6.IdEstudiante, AsignaturaId=a3.IdAsignatura,  ProfesorId=p3.IdProfesor, Calificacion=18, Fecha=DateTime.UtcNow.AddDays(-8),  CodigoQR="QR-PRG201-002" },
                            new Nota { EstudianteId=e6.IdEstudiante, AsignaturaId=a4.IdAsignatura,  ProfesorId=p3.IdProfesor, Calificacion=16, Fecha=DateTime.UtcNow.AddDays(-3),  CodigoQR="QR-BD201-001" }
                        );
                        await _context.SaveChangesAsync();
                        log.Add("Notas: 12 creadas.");
                    }

                    // ── 8. ANUNCIOS ───────────────────────────────────────────────────────
                    if (!await _context.Anuncios.AnyAsync())
                    {
                        _context.Anuncios.AddRange(
                            new Anuncio { Titulo="Bienvenida al Período Académico 2025-I", Contenido="La Universidad Politécnica Territorial de Mérida da la bienvenida a toda la comunidad universitaria al inicio del período académico 2025-I. Les deseamos éxito en sus actividades académicas.", FechaPublicacion=DateTime.UtcNow.AddDays(-30), Autor="Rectorado" },
                            new Anuncio { Titulo="Inicio de Inscripciones — Período 2025-II", Contenido="Se informa que el proceso de inscripciones para el período 2025-II estará disponible del 15 al 30 de junio. Revisa los requisitos en la coordinación académica.", FechaPublicacion=DateTime.UtcNow.AddDays(-10), Autor="Coordinación Académica" },
                            new Anuncio { Titulo="Mantenimiento Programado del Sistema", Contenido="El sistema UPTMDigital estará en mantenimiento el día sábado 15/03 de 8:00am a 12:00pm. Durante ese tiempo no estará disponible.", FechaPublicacion=DateTime.UtcNow.AddDays(-5), Autor="Soporte Técnico" },
                            new Anuncio { Titulo="Convocatoria — Feria de Proyectos Tecnológicos", Contenido="Se invita a todos los estudiantes y profesores a participar en la IV Feria de Proyectos Tecnológicos a realizarse el 25 de abril en el patio principal de la institución.", FechaPublicacion=DateTime.UtcNow.AddDays(-2), Autor="Coordinación de Investigación" },
                            new Anuncio { Titulo="Actualización de Notas — Primer Corte", Contenido="Los profesores deberán registrar las calificaciones del primer corte antes del 20 del presente mes. Se recuerda que las notas deben ser ingresadas directamente en la plataforma.", FechaPublicacion=DateTime.UtcNow.AddDays(-1), Autor="Coordinación Docente" }
                        );
                        await _context.SaveChangesAsync();
                        log.Add("Anuncios: 5 creados.");
                    }

                    // ── 9. ASISTENCIAS ────────────────────────────────────────────────────
                    if (!await _context.Asistencias.AnyAsync())
                    {
                        _context.Asistencias.AddRange(
                            new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=a1.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-14), Estado="Presente" },
                            new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=a1.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-7),  Estado="Presente" },
                            new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=a2.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-14), Estado="Presente" },
                            new Asistencia { EstudianteId=e1.IdEstudiante, AsignaturaId=a2.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-7),  Estado="Ausente" },
                            new Asistencia { EstudianteId=e2.IdEstudiante, AsignaturaId=a1.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-14), Estado="Presente" },
                            new Asistencia { EstudianteId=e2.IdEstudiante, AsignaturaId=a2.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-7),  Estado="Presente" },
                            new Asistencia { EstudianteId=e2.IdEstudiante, AsignaturaId=a3.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-3),  Estado="Justificado" },
                            new Asistencia { EstudianteId=e3.IdEstudiante, AsignaturaId=a7.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-14), Estado="Presente" },
                            new Asistencia { EstudianteId=e3.IdEstudiante, AsignaturaId=a7.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-7),  Estado="Ausente" },
                            new Asistencia { EstudianteId=e4.IdEstudiante, AsignaturaId=a7.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-7),  Estado="Presente" },
                            new Asistencia { EstudianteId=e5.IdEstudiante, AsignaturaId=a8.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-14), Estado="Presente" },
                            new Asistencia { EstudianteId=e6.IdEstudiante, AsignaturaId=a3.IdAsignatura, Fecha=DateTime.UtcNow.AddDays(-3),  Estado="Presente" }
                        );
                        await _context.SaveChangesAsync();
                        log.Add("Asistencias: 12 creadas.");
                    }

                    // ── 10. CONSTANCIAS ───────────────────────────────────────────────────
                    if (!await _context.Constancias.AnyAsync())
                    {
                        _context.Constancias.AddRange(
                            new Constancia { EstudianteId=e1.IdEstudiante, TipoConstancia="Estudio",         FechaSolicitud=DateTime.UtcNow.AddDays(-20), Estado="Emitida",    CodigoQR="CONST-001", ArchivoUrl="https://uptmdigital-api.onrender.com/constancias/CONST-001.pdf" },
                            new Constancia { EstudianteId=e1.IdEstudiante, TipoConstancia="Buena Conducta",   FechaSolicitud=DateTime.UtcNow.AddDays(-10), Estado="Emitida",    CodigoQR="CONST-002", ArchivoUrl="https://uptmdigital-api.onrender.com/constancias/CONST-002.pdf" },
                            new Constancia { EstudianteId=e2.IdEstudiante, TipoConstancia="Notas",            FechaSolicitud=DateTime.UtcNow.AddDays(-5),  Estado="En proceso", CodigoQR="CONST-003", ArchivoUrl=null },
                            new Constancia { EstudianteId=e3.IdEstudiante, TipoConstancia="Estudio",         FechaSolicitud=DateTime.UtcNow.AddDays(-3),  Estado="Pendiente",  CodigoQR="CONST-004", ArchivoUrl=null }
                        );
                        await _context.SaveChangesAsync();
                        log.Add("Constancias: 4 creadas.");
                    }

                    // ── 11. CONTROL DE ACCESO ─────────────────────────────────────────────
                    if (!await _context.ControlAccesos.AnyAsync())
                    {
                        var accesos = new List<ControlAcceso>();
                        var personas = new[] {
                            (e1.Cedula, "Entrada", "Bloque A"), (e1.Cedula, "Salida",  "Bloque A"),
                            (e2.Cedula, "Entrada", "Bloque B"), (e2.Cedula, "Salida",  "Bloque B"),
                            (e3.Cedula, "Entrada", "Bloque A"), (e3.Cedula, "Salida",  "Bloque A"),
                            (p1.Cedula, "Entrada", "Bloque C — Docentes"), (p1.Cedula, "Salida",  "Bloque C — Docentes"),
                            (p2.Cedula, "Entrada", "Bloque C — Docentes"), (e4.Cedula, "Entrada", "Bloque D"),
                        };
                        var baseTime = DateTime.UtcNow.AddDays(-3);
                        for (int i = 0; i < personas.Length; i++)
                            accesos.Add(new ControlAcceso { Cedula=personas[i].Item1, Tipo=personas[i].Item2, Ubicacion=personas[i].Item3, FechaHora=baseTime.AddHours(i * 2) });
                        _context.ControlAccesos.AddRange(accesos);
                        await _context.SaveChangesAsync();
                        log.Add("ControlAcceso: 10 registros creados.");
                    }

                    // ── 12. REGISTROS INSTITUCIONALES (pendientes) ────────────────────────
                    if (!await _context.RegistrosInstitucionales.AnyAsync())
                    {
                        _context.RegistrosInstitucionales.AddRange(
                            new RegistroInstitucional { Cedula="V-31500001", Nombres="Roberto",  Apellidos="Gutiérrez", CarreraDepartamento="Informática",    RolEsperado="Estudiante", CorreoInstitucional="r.gutierrez@uptm.edu.ve" },
                            new RegistroInstitucional { Cedula="V-32100002", Nombres="Sofía",    Apellidos="Acosta",    CarreraDepartamento="Turismo",          RolEsperado="Estudiante", CorreoInstitucional="s.acosta@uptm.edu.ve" },
                            new RegistroInstitucional { Cedula="V-19876543", Nombres="Pedro",    Apellidos="Núñez",     CarreraDepartamento="Matemáticas",     RolEsperado="Profesor",   CorreoInstitucional="p.nunez@uptm.edu.ve" },
                            new RegistroInstitucional { Cedula="V-33001122", Nombres="Camila",   Apellidos="Blanco",    CarreraDepartamento="Administración",   RolEsperado="Estudiante", CorreoInstitucional="c.blanco@uptm.edu.ve" },
                            new RegistroInstitucional { Cedula="V-22334455", Nombres="Francisco",Apellidos="Herrera",   CarreraDepartamento="Sistemas",         RolEsperado="Profesor",   CorreoInstitucional="f.herrera@uptm.edu.ve" }
                        );
                        await _context.SaveChangesAsync();
                        log.Add("RegistrosInstitucionales: 5 creados.");
                    }
            }
            catch (Exception ex) when (IsTransientDbException(ex))
            {
                return StatusCode(StatusCodes.Status503ServiceUnavailable, new
                {
                    message = "Error transitorio de base de datos. Reintente en unos segundos.",
                    detail = ex.Message
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al poblar la base de datos.", detail = ex.Message });
            }

            return Ok(new
            {
                message = "Base de datos poblada con data de demostración.",
                credenciales = new[]
                {
                    new { usuario="prof_garcia / prof_mendoza / prof_torres / prof_ramirez", pass="123456", rol="Profesor" },
                    new { usuario="est_rodriguez / est_lopez / est_fernandez / est_perez / est_morales / est_vargas / est_castillo / est_jimenez", pass="123456", rol="Estudiante" }
                },
                log
            });
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
                var rolesNames = new[] { "Administrador", "Profesor", "Estudiante", "Seguridad" };
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
                if (!await _context.Profesores.AnyAsync(p => p.UsuarioLogin == "profesor1"))
                {
                    var newProf = new Profesor
                    {
                        Cedula = "V-99999991",
                        Nombres = "Juan",
                        Apellidos = "Profesor",
                        CorreoInstitucional = "juan@uptm.edu.ve",
                        Telefono = "0412-1111111",
                        UsuarioLogin = "profesor1",
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
                        if (!await _context.Estudiantes.AnyAsync(e => e.UsuarioLogin == "estudiante1"))
                        {
                            var newEst = new Estudiante
                            {
                                Cedula = "V-15000000",
                                Nombres = "Angel",
                                Apellidos = "Estudiante",
                                CorreoInstitucional = "angel@uptm.edu.ve",
                                Direccion = "Mérida",
                                UsuarioLogin = "estudiante1"
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
                    if (estudiante != null && string.IsNullOrEmpty(estudiante.UsuarioLogin))
                    {
                        estudiante.UsuarioLogin = "estudiante1";
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

                        // Create associated Professor entity
                        var newProf = new Profesor
                        {
                            Cedula = "V-22222222",
                            Nombres = "Maria Perez",
                            Apellidos = "Docente",
                            CorreoInstitucional = "maria@uptm.edu.ve",
                            Telefono = "0412-2222222",
                            UsuarioLogin = "profesor2"
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
                            UsuarioLogin = "estudiante2"
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
                var p1 = await _context.Profesores.FirstOrDefaultAsync(p => p.UsuarioLogin == "profesor1");
                var p2 = await _context.Profesores.FirstOrDefaultAsync(p => p.UsuarioLogin == "profesor2");
                var e1 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioLogin == "estudiante1");
                var e2 = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioLogin == "estudiante2");

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
                            a = new Asignatura { Codigo = code, Nombre = name, Semestre = sem, Creditos = cred, Departamento = "General", ProfesorId = profId };
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
                            _context.Inscripciones.Add(new Inscripcion { EstudianteId = estId, AsignaturaId = asigId, Periodo = "2025-I", FechaInscripcion = DateTime.Now, Estado = "Inscrito" });
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
                        new RegistroInstitucional { Cedula = "V-10000001", Nombres = "Roberto", Apellidos = "Gomez", CarreraDepartamento = "Matematica", RolEsperado = "Profesor", CorreoInstitucional = "roberto@uptm.edu.ve" }
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
    }
}
