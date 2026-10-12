using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace UPTMDigital.API.Models.Daree
{
    /// <summary>
    /// Perfil completo del estudiante en Daree (Control de Estudios).
    /// Contiene datos demográficos, socioeconómicos y académicos.
    /// Tabla: estudiantes | BD: hc2896_control_estudios_test (MariaDB)
    /// </summary>
    [Table("estudiantes")]
    public class DareeEstudiante
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("cedula")]
        public string Cedula { get; set; } = null!;

        [Column("apellidos")]
        public string Apellidos { get; set; } = null!;

        [Column("nombres")]
        public string Nombres { get; set; } = null!;

        [Column("sexo")]
        public string? Sexo { get; set; }

        [Column("estadocivil")]
        public string? EstadoCivil { get; set; }

        [Column("fechanac")]
        public DateTime? FechaNac { get; set; }

        [Column("edad")]
        public int? Edad { get; set; }

        [Column("sangre")]
        public string? Sangre { get; set; }

        [Column("alergias")]
        public string? Alergias { get; set; }

        [Column("discapacidad")]
        public string? Discapacidad { get; set; }

        [Column("disc_desc")]
        public string? DiscDesc { get; set; }

        [Column("indigena")]
        public string? Indigena { get; set; }

        // ─── Datos de nacimiento ─────────────────────────────
        [Column("nac_pais")]
        public string? NacPais { get; set; }

        [Column("nac_estado")]
        public string? NacEstado { get; set; }

        [Column("nac_municipio")]
        public string? NacMunicipio { get; set; }

        [Column("nac_parroquia")]
        public string? NacParroquia { get; set; }

        // ─── Datos de residencia ─────────────────────────────
        [Column("res_estado")]
        public string? ResEstado { get; set; }

        [Column("res_municipio")]
        public string? ResMunicipio { get; set; }

        [Column("res_parroquia")]
        public string? ResParroquia { get; set; }

        [Column("direccion")]
        public string? Direccion { get; set; }

        // ─── Contacto ───────────────────────────────────────
        [Column("tlf_hab")]
        public string? TlfHab { get; set; }

        [Column("tlf_mov")]
        public string? TlfMov { get; set; }

        [Column("correo")]
        public string? Correo { get; set; }

        [Column("telefono")]
        public string? Telefono { get; set; }

        // ─── Contacto de emergencia ─────────────────────────
        [Column("ref_nombre")]
        public string? RefNombre { get; set; }

        [Column("ref_telefono")]
        public string? RefTelefono { get; set; }

        // ─── Datos académicos previos ───────────────────────
        [Column("institucion")]
        public string? Institucion { get; set; }

        [Column("titulo")]
        public string? Titulo { get; set; }

        [Column("promedio")]
        public decimal? Promedio { get; set; }

        // ─── Datos académicos actuales ──────────────────────
        [Column("pnf_id")]
        public int PnfId { get; set; }

        [Column("trayecto")]
        public string? Trayecto { get; set; }

        [Column("trimestre")]
        public string? Trimestre { get; set; }

        [Column("codigo_alumno")]
        public string? CodigoAlumno { get; set; }

        [Column("estatus")]
        public string? Estatus { get; set; }

        [Column("modalidad")]
        public string? Modalidad { get; set; }

        // ─── Carnet ─────────────────────────────────────────
        [Column("numero_carnet")]
        public string? NumeroCarnet { get; set; }

        [Column("carnet_codigo")]
        public string? CarnetCodigo { get; set; }

        // ─── Datos laborales ────────────────────────────────
        [Column("trabaja")]
        public string? Trabaja { get; set; }

        [Column("empresa_nombre")]
        public string? EmpresaNombre { get; set; }

        [Column("medio_traslado")]
        public string? MedioTraslado { get; set; }

        // ─── Expediente ─────────────────────────────────────
        [Column("expediente_estado")]
        public string? ExpedienteEstado { get; set; }

        [Column("fecha_registro")]
        public DateTime? FechaRegistro { get; set; }

        [Column("activo")]
        public bool? Activo { get; set; }

        [Column("sede_id")]
        public int? SedeId { get; set; }
    }
}
