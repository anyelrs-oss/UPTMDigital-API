using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Data
{
    public class UPTMDigitalContext : DbContext
    {
        public UPTMDigitalContext(DbContextOptions<UPTMDigitalContext> options)
            : base(options)
        {
        }

        public DbSet<Usuario> Usuarios { get; set; }
        public DbSet<ControlAcceso> ControlAccesos { get; set; } = null!;
        public DbSet<Rol> Roles { get; set; } = null!;
        public DbSet<Estudiante> Estudiantes { get; set; } = null!;
        public DbSet<Profesor> Profesores { get; set; } = null!;
        public DbSet<Asignatura> Asignaturas { get; set; } = null!;
        public DbSet<Inscripcion> Inscripciones { get; set; } = null!;
        public DbSet<Nota> Notas { get; set; } = null!;
        public DbSet<Horario> Horarios { get; set; } = null!;
        public DbSet<Anuncio> Anuncios { get; set; } = null!;
        public DbSet<Mensaje> Mensajes { get; set; } = null!;
        public DbSet<Asistencia> Asistencias { get; set; } = null!;
        public DbSet<Constancia> Constancias { get; set; } = null!;
        public DbSet<RegistroInstitucional> RegistrosInstitucionales { get; set; } = null!;
        public DbSet<Carrera> Carreras { get; set; } = null!;
        public DbSet<Semestre> Semestres { get; set; } = null!;
        public DbSet<Periodo> Periodos { get; set; } = null!;
    }
}