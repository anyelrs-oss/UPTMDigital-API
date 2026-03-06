using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SetupController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public SetupController(UPTMDigitalContext context)
        {
            _context = context;
        }

        [HttpPost("apply-changes")]
        public async Task<IActionResult> ApplyChanges()
        {
            var log = new List<string>();

            // 1. Update Schema
            try
            {
                log.Add("Schema generation is now handled by EF Core Migrations.");
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
                foreach (var rName in rolesNames) {
                    if (!await _context.Roles.AnyAsync(r => r.NombreRol == rName)) {
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
                     if (rolProf == null) {
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
                     var newProf = new Profesor { 
                            Cedula = "V-99999991", Nombres = "Juan", Apellidos = "Profesor", 
                            CorreoInstitucional = "juan@uptm.edu.ve", Telefono = "0412-1111111", UsuarioLogin = "profesor1",
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
                foreach (var uname in usersToReset) {
                    var u = await _context.Usuarios.FirstOrDefaultAsync(x => x.NombreUsuario == uname);
                    if (u != null) {
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
                    if (rolProf != null) {
                        prof2User = new Usuario { NombreUsuario = "profesor2", ContrasenaHash = "123456", RolId = rolProf.IdRol };
                        _context.Usuarios.Add(prof2User);
                        await _context.SaveChangesAsync();
                        log.Add("Created user 'profesor2'");
                        
                        // Create associated Professor entity
                        var newProf = new Profesor { 
                            Cedula = "V-22222222", Nombres = "Maria Perez", Apellidos = "Docente", 
                            CorreoInstitucional = "maria@uptm.edu.ve", Telefono = "0412-2222222", UsuarioLogin = "profesor2" 
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
                    if (rolEst != null) {
                        est2User = new Usuario { NombreUsuario = "estudiante2", ContrasenaHash = "123456", RolId = rolEst.IdRol };
                        _context.Usuarios.Add(est2User);
                        await _context.SaveChangesAsync();
                        log.Add("Created user 'estudiante2'");

                        // Create associated Student entity
                        var newEst = new Estudiante { 
                            Cedula = "V-33333333", Nombres = "Carlos Ruiz", Apellidos = "Alumno", 
                            CorreoInstitucional = "carlos@uptm.edu.ve", Direccion = "Centro", UsuarioLogin = "estudiante2" 
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
                    if (rolSeg != null) {
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
                    async Task<Asignatura> EnsureAsignatura(string code, string name, int sem, int cred, int profId) {
                        var a = await _context.Asignaturas.FirstOrDefaultAsync(x => x.Codigo == code);
                        if (a == null) {
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
                    async Task EnsureInscripcion(int estId, int asigId) {
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
                    if (!await _context.Notas.AnyAsync()) {
                         _context.Notas.AddRange(
                            new Nota { EstudianteId = e1.IdEstudiante, AsignaturaId = asig1.IdAsignatura, Calificacion = 18, ProfesorId = p1.IdProfesor, CodigoQR = "QR-MAT-001", Fecha = DateTime.Now.AddDays(-10) },
                            new Nota { EstudianteId = e1.IdEstudiante, AsignaturaId = asig2.IdAsignatura, Calificacion = 16, ProfesorId = p2.IdProfesor, CodigoQR = "QR-PROG-001", Fecha = DateTime.Now.AddDays(-5) },
                            new Nota { EstudianteId = e2.IdEstudiante, AsignaturaId = asig3.IdAsignatura, Calificacion = 15, ProfesorId = p1.IdProfesor, CodigoQR = "QR-BD-001", Fecha = DateTime.Now.AddDays(-2) }
                        );
                        log.Add("Seeded initial Notas.");
                    }

                    // 3.5 Mensajes (Expanded)
                    if (!await _context.Mensajes.AnyAsync(m => m.AsignaturaId == asig2.IdAsignatura)) {
                         _context.Mensajes.AddRange(
                            new Mensaje { AsignaturaId = asig2.IdAsignatura, Contenido = "Bienvenidos al curso de Programación I", FechaEnvio = DateTime.Now.AddDays(-10), EmisorNombre = p2.Nombres + " " + p2.Apellidos },
                            new Mensaje { AsignaturaId = asig2.IdAsignatura, Contenido = "Recuerden instalar Visual Studio Code", FechaEnvio = DateTime.Now.AddDays(-8), EmisorNombre = p2.Nombres + " " + p2.Apellidos },
                            new Mensaje { AsignaturaId = asig2.IdAsignatura, Contenido = "¿Cuándo es el primer examen?", FechaEnvio = DateTime.Now.AddDays(-7), EmisorNombre = e1.Nombres + " " + e1.Apellidos }
                         );
                         log.Add("Seeded messages for PROG101.");
                    }

                    // 3.6 Horarios (Expanded)
                    if (!await _context.Horarios.AnyAsync()) {
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
                    if (!await _context.Asistencias.AnyAsync()) {
                        _context.Asistencias.AddRange(
                            new Asistencia { EstudianteId = e1.IdEstudiante, AsignaturaId = asig1.IdAsignatura, Fecha = DateTime.Now.AddDays(-7), Estado = "Presente" },
                            new Asistencia { EstudianteId = e1.IdEstudiante, AsignaturaId = asig1.IdAsignatura, Fecha = DateTime.Now.AddDays(-2), Estado = "Ausente" },
                            new Asistencia { EstudianteId = e1.IdEstudiante, AsignaturaId = asig2.IdAsignatura, Fecha = DateTime.Now.AddDays(-5), Estado = "Presente" }
                        );
                        log.Add("Seeded Asistencias.");
                    }

                    // 3.8 Constancias (New)
                    if (!await _context.Constancias.AnyAsync()) {
                        _context.Constancias.Add(
                            new Constancia { EstudianteId = e1.IdEstudiante, TipoConstancia = "Estudio", FechaSolicitud = DateTime.Now.AddMonths(-1), ArchivoUrl = "https://example.com/constancia1.pdf", Estado = "Emitida" }
                        );
                        log.Add("Seeded Constancias.");
                    }
                
                }
                
                // --- REGISTRO INSTITUCIONAL (MOCK) ---
                    // Tables should exist via EF Core migrations

                    if (!await _context.RegistrosInstitucionales.AnyAsync()) {
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
