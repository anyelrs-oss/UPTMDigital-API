using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Data
{
    /// <summary>
    /// Contexto de solo-lectura para la "Base Maestro" de nómina institucional.
    /// En producción, apunta a la PC local (o mirror en Somee).
    /// Solo expone RegistroInstitucional para validar cédulas durante el onboarding.
    /// </summary>
    public class NominaContext : DbContext
    {
        public NominaContext(DbContextOptions<NominaContext> options)
            : base(options)
        {
        }

        public DbSet<RegistroInstitucional> RegistrosInstitucionales { get; set; } = null!;
    }
}
