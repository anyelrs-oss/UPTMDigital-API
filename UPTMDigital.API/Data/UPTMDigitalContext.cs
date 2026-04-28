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
        }
    }
}