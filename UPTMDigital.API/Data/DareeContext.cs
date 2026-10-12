using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Models.Daree;

namespace UPTMDigital.API.Data
{
    /// <summary>
    /// Contexto de solo-lectura para la base de datos de Daree (Control de Estudios).
    /// Motor: MariaDB 10.4 en Infomaniak (hc2896.myd.infomaniak.com).
    /// Expone tablas académicas: PNF, pensum, secciones, horarios, periodos, etc.
    /// NUNCA realizar operaciones de escritura contra esta BD.
    /// </summary>
    public class DareeContext : DbContext
    {
        public DareeContext(DbContextOptions<DareeContext> options)
            : base(options) { }

        public DbSet<DareePnf> Pnfs { get; set; } = null!;
        public DbSet<DareePensum> Pensum { get; set; } = null!;
        public DbSet<DareeSeccion> Secciones { get; set; } = null!;
        public DbSet<DareeHorario> Horarios { get; set; } = null!;
        public DbSet<DareePeriodo> Periodos { get; set; } = null!;
        public DbSet<DareePrelacion> Prelaciones { get; set; } = null!;
        public DbSet<DareeCargaDocente> CargaDocente { get; set; } = null!;
        public DbSet<DareeAula> Aulas { get; set; } = null!;
        public DbSet<DareeInscripcionNota> InscripcionesNotas { get; set; } = null!;
        public DbSet<DareeEstudiante> Estudiantes { get; set; } = null!;
        public DbSet<DareeInscripcion> Inscripciones { get; set; } = null!;
        public DbSet<DareeHistorialAcademico> HistorialAcademico { get; set; } = null!;
        public DbSet<DareeDocente> Docentes { get; set; } = null!;
        public DbSet<DareeAsistencia> Asistencias { get; set; } = null!;
        public DbSet<DareeEvaluacion> Evaluaciones { get; set; } = null!;
    }
}
