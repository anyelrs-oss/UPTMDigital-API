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
        public DbSet<Notificacion> Notificaciones { get; set; } = null!;
        public DbSet<Aula> Aulas { get; set; } = null!;
        public DbSet<SolicitudApertura> SolicitudApertura { get; set; } = null!;
        public DbSet<PinAsistencia> PinesAsistencia { get; set; } = null!;
        public DbSet<EvaluacionConfig> EvaluacionesConfig { get; set; } = null!;
        public DbSet<AuditLog> AuditLogs { get; set; } = null!;
        public DbSet<ArancelValidacion> ArancelesValidaciones { get; set; } = null!;
        public DbSet<Coordinador> Coordinadores { get; set; } = null!;
        public DbSet<GlobalSetting> GlobalSettings { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ControlAcceso tiene dos FK a Usuario (escaneado y guardia)
            // EF necesita saber cuál es cuál para evitar cascadas múltiples
            modelBuilder.Entity<ControlAcceso>()
                .HasOne(c => c.Usuario)
                .WithMany()
                .HasForeignKey(c => c.UsuarioId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ControlAcceso>()
                .HasOne(c => c.PersonalSeguridad)
                .WithMany()
                .HasForeignKey(c => c.PersonalSeguridadId)
                .OnDelete(DeleteBehavior.Restrict);

            // Mensaje → Usuario (emisor)
            modelBuilder.Entity<Mensaje>()
                .HasOne(m => m.Usuario)
                .WithMany()
                .HasForeignKey(m => m.UsuarioId)
                .OnDelete(DeleteBehavior.Restrict);

            // Mensaje → Asignatura
            modelBuilder.Entity<Mensaje>()
                .HasOne(m => m.Asignatura)
                .WithMany()
                .HasForeignKey(m => m.AsignaturaId)
                .OnDelete(DeleteBehavior.Restrict);

            // Notificacion → Usuario (destinatario)
            modelBuilder.Entity<Notificacion>()
                .HasOne(n => n.Usuario)
                .WithMany()
                .HasForeignKey(n => n.UsuarioId)
                .OnDelete(DeleteBehavior.Restrict);

            // Anuncio → Usuario (autor)
            modelBuilder.Entity<Anuncio>()
                .HasOne(a => a.Usuario)
                .WithMany()
                .HasForeignKey(a => a.UsuarioId)
                .OnDelete(DeleteBehavior.Restrict);

            // Índices para optimización de búsquedas y relaciones frecuentes
            modelBuilder.Entity<Usuario>()
                .HasIndex(u => u.Cedula).IsUnique();

            modelBuilder.Entity<Estudiante>()
                .HasIndex(e => e.Cedula).IsUnique();
            modelBuilder.Entity<Estudiante>()
                .HasIndex(e => e.UsuarioId);
            modelBuilder.Entity<Nota>()
                .HasIndex(n => n.EstudianteId);
            modelBuilder.Entity<Asistencia>()
                .HasIndex(a => a.EstudianteId);

            // Relaciones de SolicitudApertura
            modelBuilder.Entity<SolicitudApertura>()
                .HasOne(s => s.PersonalSeguridad)
                .WithMany()
                .HasForeignKey(s => s.PersonalSeguridadId)
                .OnDelete(DeleteBehavior.Restrict);

            // Vinculación PinAsistencia → Usuario (Coordinador)
            modelBuilder.Entity<PinAsistencia>()
                .HasOne(p => p.Coordinador)
                .WithMany()
                .HasForeignKey(p => p.CoordinadorId)
                .OnDelete(DeleteBehavior.Restrict);

            // Vinculación Usuario → RegistroInstitucional
            modelBuilder.Entity<Usuario>()
                .HasOne(u => u.RegistroInstitucional)
                .WithMany()
                .HasForeignKey(u => u.RegistroInstitucionalId)
                .OnDelete(DeleteBehavior.SetNull);
        }
    }
}