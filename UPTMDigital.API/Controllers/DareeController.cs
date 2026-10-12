using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UPTMDigital.API.Data;
using UPTMDigital.API.Helpers;

namespace UPTMDigital.API.Controllers
{
    /// <summary>
    /// Endpoints de solo lectura para datos académicos de Daree (Control de Estudios).
    /// Consume DareeContext → MariaDB remoto en Infomaniak.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class DareeController : ControllerBase
    {
        private readonly DareeContext _daree;
        private readonly UPTMDigitalContext _context;

        public DareeController(DareeContext daree, UPTMDigitalContext context)
        {
            _daree = daree;
            _context = context;
        }

        // ─── Health Check ────────────────────────────────────────────

        /// <summary>
        /// Verifica conectividad con la BD de Daree.
        /// GET /api/daree/health
        /// </summary>
        [HttpGet("health")]
        [AllowAnonymous]
        public async Task<IActionResult> Health()
        {
            try
            {
                var canConnect = await _daree.Database.CanConnectAsync();
                if (!canConnect)
                    return StatusCode(503, new { success = false, message = "No se puede conectar a la BD de Daree." });

                var pnfCount = await _daree.Pnfs.CountAsync();
                var periodoActivo = await _daree.Periodos.FirstOrDefaultAsync(p => p.Activo);
                var pensumCount = await _daree.Pensum.CountAsync();
                var seccionesCount = await _daree.Secciones.CountAsync();
                var horariosCount = await _daree.Horarios.CountAsync();
                var prelacionesCount = await _daree.Prelaciones.CountAsync();
                var aulasCount = await _daree.Aulas.CountAsync();
                var cargaDocenteCount = await _daree.CargaDocente.CountAsync();

                // Sample: first 3 PNFs
                var samplePnfs = await _daree.Pnfs
                    .Where(p => p.Activo)
                    .OrderBy(p => p.Codigo)
                    .Take(3)
                    .Select(p => new { p.Codigo, p.Nombre, p.ColorHex })
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    message = "Conexión a Daree exitosa.",
                    data = new
                    {
                        motor = "MariaDB 10.4",
                        host = "hc2896.myd.infomaniak.com",
                        periodoActivo = periodoActivo?.Codigo ?? "ninguno",
                        tablas = new
                        {
                            pnfs = pnfCount,
                            pensum = pensumCount,
                            secciones = seccionesCount,
                            horarios = horariosCount,
                            prelaciones = prelacionesCount,
                            aulas = aulasCount,
                            cargaDocente = cargaDocenteCount
                        },
                        samplePnfs
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(503, new
                {
                    success = false,
                    message = "Error al conectar con Daree.",
                    error = ex.Message
                });
            }
        }

        // ─── PNFs (Carreras) ─────────────────────────────────────────

        /// <summary>
        /// Lista todos los PNF activos.
        /// GET /api/daree/pnfs
        /// </summary>
        [HttpGet("pnfs")]
        [Authorize]
        public async Task<IActionResult> GetPnfs()
        {
            var pnfs = await _daree.Pnfs
                .Where(p => p.Activo)
                .OrderBy(p => p.Codigo)
                .Select(p => new
                {
                    p.Id,
                    p.Codigo,
                    p.Nombre,
                    p.ColorHex
                })
                .ToListAsync();

            return Ok(new { success = true, data = pnfs, count = pnfs.Count });
        }

        // ─── Pensum (Malla Curricular) ───────────────────────────────

        /// <summary>
        /// Malla curricular completa de un PNF.
        /// GET /api/daree/pensum/{pnfId}
        /// </summary>
        [HttpGet("pensum/{pnfId}")]
        [Authorize]
        public async Task<IActionResult> GetPensum(int pnfId)
        {
            var pnf = await _daree.Pnfs.FindAsync(pnfId);
            if (pnf == null)
                return NotFound(new { success = false, message = $"PNF con id {pnfId} no encontrado." });

            var unidades = await _daree.Pensum
                .Where(p => p.PnfId == pnfId && (p.Activo ?? true))
                .OrderBy(p => p.Trayecto)
                .ThenBy(p => p.Trimestre)
                .ThenBy(p => p.CodigoUc)
                .Select(p => new
                {
                    p.Id,
                    p.Trayecto,
                    p.Trimestre,
                    p.CodigoUc,
                    p.NombreUc,
                    p.UnidadesCredito,
                    p.TipoUc,
                    p.HorasAcademicas,
                    p.NotaMinima,
                    p.AsistenciaMinima,
                    p.PermitePer
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                pnf = new { pnf.Id, pnf.Codigo, pnf.Nombre },
                data = unidades,
                count = unidades.Count
            });
        }

        // ─── Periodo Activo ──────────────────────────────────────────

        /// <summary>
        /// Obtiene el periodo académico activo.
        /// GET /api/daree/periodo-activo
        /// </summary>
        [HttpGet("periodo-activo")]
        [Authorize]
        public async Task<IActionResult> GetPeriodoActivo()
        {
            var periodo = await _daree.Periodos
                .FirstOrDefaultAsync(p => p.Activo);

            if (periodo == null)
                return NotFound(new { success = false, message = "No hay periodo activo." });

            return Ok(new
            {
                success = true,
                data = new
                {
                    periodo.Id,
                    periodo.Codigo,
                    periodo.Nombre,
                    periodo.Descripcion,
                    periodo.FechaInicio,
                    periodo.FechaFin,
                    periodo.Estatus,
                    periodo.Fase,
                    periodo.BloqueaInscripciones,
                    periodo.BloqueaNotas
                }
            });
        }

        // ─── Secciones ──────────────────────────────────────────────

        /// <summary>
        /// Lista secciones con filtros opcionales.
        /// GET /api/daree/secciones?pnfId=3&periodo=2026-I&trayecto=Trayecto I
        /// </summary>
        [HttpGet("secciones")]
        [Authorize]
        public async Task<IActionResult> GetSecciones(
            [FromQuery] int? pnfId,
            [FromQuery] string? periodo,
            [FromQuery] string? trayecto)
        {
            var query = _daree.Secciones.AsQueryable();

            if (pnfId.HasValue)
                query = query.Where(s => s.PnfId == pnfId.Value);

            if (!string.IsNullOrEmpty(periodo))
                query = query.Where(s => s.Periodo == periodo);

            if (!string.IsNullOrEmpty(trayecto))
                query = query.Where(s => s.Trayecto == trayecto);

            var secciones = await query
                .OrderBy(s => s.PnfId)
                .ThenBy(s => s.Trayecto)
                .ThenBy(s => s.Trimestre)
                .ThenBy(s => s.CodigoUc)
                .Select(s => new
                {
                    s.Id,
                    s.Periodo,
                    s.PnfId,
                    s.Trayecto,
                    s.Trimestre,
                    s.CodigoUc,
                    s.NombreUc,
                    s.LetraSeccion,
                    s.DocenteNombre,
                    s.DocenteCedula,
                    s.Inscritos,
                    s.CupoMaximo,
                    s.Edificio,
                    s.Aula,
                    s.Horario,
                    s.Estado,
                    s.EsPer,
                    s.TipoSeccion
                })
                .Take(500)
                .ToListAsync();

            // Normalize cedulas post-query (Daree uses V-prefix, UPTM uses plain digits)
            var normalized = secciones.Select(s => new
            {
                s.Id, s.Periodo, s.PnfId, s.Trayecto, s.Trimestre,
                s.CodigoUc, s.NombreUc, s.LetraSeccion, s.DocenteNombre,
                DocenteCedula = CedulaHelper.Normalize(s.DocenteCedula),
                DocenteCedulaOriginal = s.DocenteCedula,
                s.Inscritos, s.CupoMaximo, s.Edificio, s.Aula,
                s.Horario, s.Estado, s.EsPer, s.TipoSeccion
            }).ToList();

            return Ok(new { success = true, data = normalized, count = normalized.Count });
        }

        // ─── Horarios ────────────────────────────────────────────────

        /// <summary>
        /// Bloques horarios de una sección específica.
        /// GET /api/daree/horarios/{seccionId}
        /// </summary>
        [HttpGet("horarios/{seccionId}")]
        [Authorize]
        public async Task<IActionResult> GetHorarios(string seccionId)
        {
            var horarios = await _daree.Horarios
                .Where(h => h.SeccionId == seccionId)
                .OrderBy(h => h.DiaSemana)
                .ThenBy(h => h.HoraInicio)
                .Select(h => new
                {
                    h.Id,
                    h.DiaSemana,
                    HoraInicio = h.HoraInicio.HasValue ? h.HoraInicio.Value.ToString(@"hh\:mm") : null,
                    HoraFin = h.HoraFin.HasValue ? h.HoraFin.Value.ToString(@"hh\:mm") : null,
                    h.Aula,
                    h.Edificio,
                    h.NombreUc,
                    h.CodigoUc,
                    h.Modalidad,
                    h.BloqueNum,
                    h.BloqueMinutos
                })
                .ToListAsync();

            return Ok(new { success = true, data = horarios, count = horarios.Count });
        }

        // ─── Horarios por PNF ────────────────────────────────────────

        /// <summary>
        /// Todos los horarios de un PNF en el periodo activo.
        /// GET /api/daree/horarios-pnf/{pnfId}
        /// </summary>
        [HttpGet("horarios-pnf/{pnfId}")]
        [Authorize]
        public async Task<IActionResult> GetHorariosPorPnf(int pnfId)
        {
            var periodoActivo = await _daree.Periodos
                .FirstOrDefaultAsync(p => p.Activo);

            if (periodoActivo == null)
                return NotFound(new { success = false, message = "No hay periodo activo." });

            var horarios = await _daree.Horarios
                .Where(h => h.PnfId == pnfId && h.PeriodoId == periodoActivo.Id)
                .OrderBy(h => h.DiaSemana)
                .ThenBy(h => h.HoraInicio)
                .Select(h => new
                {
                    h.Id,
                    h.SeccionId,
                    h.DiaSemana,
                    HoraInicio = h.HoraInicio.HasValue ? h.HoraInicio.Value.ToString(@"hh\:mm") : null,
                    HoraFin = h.HoraFin.HasValue ? h.HoraFin.Value.ToString(@"hh\:mm") : null,
                    h.Aula,
                    h.Edificio,
                    h.NombreUc,
                    h.CodigoUc,
                    h.DocenteCedula,
                    h.Modalidad,
                    h.PnfColor
                })
                .ToListAsync();

            // Normalize cedulas post-query
            var normalized = horarios.Select(h => new
            {
                h.Id, h.SeccionId, h.DiaSemana, h.HoraInicio, h.HoraFin,
                h.Aula, h.Edificio, h.NombreUc, h.CodigoUc,
                DocenteCedula = CedulaHelper.Normalize(h.DocenteCedula),
                h.Modalidad, h.PnfColor
            }).ToList();

            return Ok(new
            {
                success = true,
                periodo = periodoActivo.Codigo,
                data = normalized,
                count = normalized.Count
            });
        }

        // ─── Prelaciones ─────────────────────────────────────────────

        /// <summary>
        /// Cadena de prerrequisitos de un PNF.
        /// GET /api/daree/prelaciones/{pnfId}
        /// </summary>
        [HttpGet("prelaciones/{pnfId}")]
        [Authorize]
        public async Task<IActionResult> GetPrelaciones(int pnfId)
        {
            var prelaciones = await _daree.Prelaciones
                .Where(p => p.PnfId == pnfId && p.Activo)
                .OrderBy(p => p.UcCodigo)
                .Select(p => new
                {
                    p.UcCodigo,
                    p.UcNombre,
                    p.RequiereCodigo,
                    p.RequiereNombre,
                    p.Tipo
                })
                .ToListAsync();

            return Ok(new { success = true, data = prelaciones, count = prelaciones.Count });
        }

        // ─── Aulas ───────────────────────────────────────────────────

        /// <summary>
        /// Catálogo de aulas activas.
        /// GET /api/daree/aulas
        /// </summary>
        [HttpGet("aulas")]
        [Authorize]
        public async Task<IActionResult> GetAulas()
        {
            var aulas = await _daree.Aulas
                .Where(a => a.Activo)
                .OrderBy(a => a.Edificio)
                .ThenBy(a => a.Codigo)
                .Select(a => new
                {
                    a.Id,
                    a.Codigo,
                    a.Nombre,
                    a.Edificio,
                    a.Capacidad,
                    a.Tipo
                })
                .ToListAsync();

            return Ok(new { success = true, data = aulas, count = aulas.Count });
        }
        // ─── Mapeo Carrera UPTM → PNF Daree ────────────────────────

        /// <summary>
        /// Busca el PNF de Daree que corresponde a una carrera UPTM.
        /// GET /api/daree/mi-pnf?carrera=Informática
        /// Hace fuzzy matching: "Informática" → "PNF en Informática"
        /// </summary>
        [HttpGet("mi-pnf")]
        [Authorize]
        public async Task<IActionResult> GetMiPnf([FromQuery] string? carrera)
        {
            if (string.IsNullOrWhiteSpace(carrera))
                return BadRequest(new { success = false, message = "Parámetro 'carrera' es requerido." });

            // Normalize: remove common prefixes and trim
            var searchTerm = carrera.Trim()
                .Replace("PNF en ", "", StringComparison.OrdinalIgnoreCase)
                .Replace("PNF ", "", StringComparison.OrdinalIgnoreCase)
                .Trim();

            // Try exact match first, then LIKE match
            var pnf = await _daree.Pnfs
                .Where(p => p.Activo)
                .FirstOrDefaultAsync(p =>
                    p.Nombre.ToLower() == searchTerm.ToLower() ||
                    p.Nombre.ToLower() == ("pnf en " + searchTerm.ToLower()) ||
                    p.Nombre.ToLower().Contains(searchTerm.ToLower()));

            if (pnf == null)
            {
                // Return list of available PNFs for debugging
                var available = await _daree.Pnfs
                    .Where(p => p.Activo)
                    .Select(p => new { p.Id, p.Nombre })
                    .ToListAsync();

                return NotFound(new
                {
                    success = false,
                    message = $"No se encontró PNF para carrera '{carrera}'.",
                    searched = searchTerm,
                    availablePnfs = available
                });
            }

            // Also load pensum summary for this PNF
            var totalUcs = await _daree.Pensum
                .CountAsync(p => p.PnfId == pnf.Id && (p.Activo ?? true));
            var totalCreditos = await _daree.Pensum
                .Where(p => p.PnfId == pnf.Id && (p.Activo ?? true))
                .SumAsync(p => p.UnidadesCredito);

            return Ok(new
            {
                success = true,
                data = new
                {
                    pnf.Id,
                    pnf.Codigo,
                    pnf.Nombre,
                    pnf.ColorHex,
                    totalUcs,
                    totalCreditos
                }
            });
        }

        // ─── Búsqueda por Cédula ─────────────────────────────────────

        /// <summary>
        /// Busca secciones/carga docente por cédula normalizada.
        /// GET /api/daree/buscar-docente?cedula=29652018
        /// Acepta cualquier formato: "29652018", "V-29652018", "v29652018"
        /// </summary>
        [HttpGet("buscar-docente")]
        [Authorize]
        public async Task<IActionResult> BuscarDocente([FromQuery] string? cedula)
        {
            if (string.IsNullOrWhiteSpace(cedula))
                return BadRequest(new { success = false, message = "Parámetro 'cedula' es requerido." });

            var normalizada = CedulaHelper.Normalize(cedula);
            var conPrefijo = CedulaHelper.ToDareeFormat(cedula);

            // Search with both formats since Daree uses V-prefix
            var secciones = await _daree.Secciones
                .Where(s => s.DocenteCedula == normalizada
                         || s.DocenteCedula == conPrefijo
                         || s.DocenteCedula == cedula.Trim())
                .OrderBy(s => s.Periodo)
                .ThenBy(s => s.CodigoUc)
                .Select(s => new
                {
                    s.Id,
                    s.Periodo,
                    s.PnfId,
                    s.CodigoUc,
                    s.NombreUc,
                    s.LetraSeccion,
                    s.DocenteNombre,
                    DocenteCedula = normalizada,
                    s.Inscritos,
                    s.CupoMaximo,
                    s.Horario,
                    s.Estado
                })
                .Take(100)
                .ToListAsync();

            return Ok(new
            {
                success = true,
                cedulaBuscada = normalizada,
                cedulaDareeFormat = conPrefijo,
                data = secciones,
                count = secciones.Count
            });
        }

        // ─── Notas del Estudiante ────────────────────────────────────

        /// <summary>
        /// Notas del estudiante logueado en Daree.
        /// GET /api/daree/mis-notas
        /// Busca por cédula normalizada en inscripciones_notas,
        /// enriquece con datos de la sección (UC, docente, periodo).
        /// </summary>
        [HttpGet("mis-notas")]
        [Authorize]
        public async Task<IActionResult> GetMisNotas()
        {
            // Get logged-in user's cedula
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioId == userId);
            if (estudiante == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado." });

            var cedulaNorm = CedulaHelper.Normalize(estudiante.Cedula);
            var cedulaDaree = CedulaHelper.ToDareeFormat(estudiante.Cedula);

            // Search with both formats
            var notas = await _daree.InscripcionesNotas
                .Where(n => n.EstudianteCedula == cedulaNorm
                         || n.EstudianteCedula == cedulaDaree
                         || n.EstudianteCedula == estudiante.Cedula)
                .OrderByDescending(n => n.FechaActualizacion)
                .ToListAsync();

            // Enrich with sección data (UC name, docente, periodo)
            var seccionIds = notas.Select(n => n.SeccionId).Distinct().ToList();
            var secciones = await _daree.Secciones
                .Where(s => seccionIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id);

            var result = notas.Select(n =>
            {
                secciones.TryGetValue(n.SeccionId, out var sec);
                return new
                {
                    n.Id,
                    n.SeccionId,
                    CodigoUc = sec?.CodigoUc ?? "N/A",
                    NombreUc = sec?.NombreUc ?? "N/A",
                    DocenteNombre = sec?.DocenteNombre,
                    Periodo = sec?.Periodo,
                    Trayecto = sec?.Trayecto,
                    Trimestre = sec?.Trimestre,
                    n.C1,
                    n.C2,
                    n.C3,
                    n.C4,
                    n.Definitiva,
                    n.Asistencia,
                    n.AsistenciaPresencial,
                    n.AsistenciaVirtual,
                    n.EstatusMateria,
                    n.EsPer,
                    n.FechaActualizacion
                };
            }).ToList();

            return Ok(new
            {
                success = true,
                cedula = cedulaNorm,
                data = result,
                count = result.Count
            });
        }

        /// <summary>
        /// Notas por cédula (para coordinadores/admin).
        /// GET /api/daree/notas-por-cedula?cedula=29652018
        /// </summary>
        [HttpGet("notas-por-cedula")]
        [Authorize]
        public async Task<IActionResult> GetNotasPorCedula([FromQuery] string? cedula)
        {
            if (string.IsNullOrWhiteSpace(cedula))
                return BadRequest(new { success = false, message = "Parámetro 'cedula' es requerido." });

            var normalizada = CedulaHelper.Normalize(cedula);
            var conPrefijo = CedulaHelper.ToDareeFormat(cedula);

            var notas = await _daree.InscripcionesNotas
                .Where(n => n.EstudianteCedula == normalizada
                         || n.EstudianteCedula == conPrefijo
                         || n.EstudianteCedula == cedula.Trim())
                .OrderByDescending(n => n.FechaActualizacion)
                .ToListAsync();

            var seccionIds = notas.Select(n => n.SeccionId).Distinct().ToList();
            var secciones = await _daree.Secciones
                .Where(s => seccionIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id);

            var result = notas.Select(n =>
            {
                secciones.TryGetValue(n.SeccionId, out var sec);
                return new
                {
                    n.Id,
                    n.SeccionId,
                    CodigoUc = sec?.CodigoUc ?? "N/A",
                    NombreUc = sec?.NombreUc ?? "N/A",
                    DocenteNombre = sec?.DocenteNombre,
                    Periodo = sec?.Periodo,
                    n.C1, n.C2, n.C3, n.C4,
                    n.Definitiva,
                    n.Asistencia,
                    n.EstatusMateria,
                    n.EsPer,
                    n.FechaActualizacion
                };
            }).ToList();

            return Ok(new
            {
                success = true,
                cedulaBuscada = normalizada,
                data = result,
                count = result.Count
            });
        }

        // ─── Perfil Estudiantil Daree ────────────────────────────────

        /// <summary>
        /// Perfil completo del estudiante en Daree (datos demográficos, académicos, contacto).
        /// GET /api/daree/mi-perfil-daree
        /// </summary>
        [HttpGet("mi-perfil-daree")]
        [Authorize]
        public async Task<IActionResult> GetMiPerfilDaree()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioId == userId);
            if (estudiante == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado en UPTM." });

            var cedulaNorm = CedulaHelper.Normalize(estudiante.Cedula);
            var cedulaDaree = CedulaHelper.ToDareeFormat(estudiante.Cedula);

            var dareeEst = await _daree.Estudiantes
                .FirstOrDefaultAsync(e => e.Cedula == cedulaNorm
                                       || e.Cedula == cedulaDaree
                                       || e.Cedula == estudiante.Cedula);

            if (dareeEst == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado en Daree." });

            // Get PNF name
            var pnf = await _daree.Pnfs.FirstOrDefaultAsync(p => p.Id == dareeEst.PnfId);

            return Ok(new
            {
                success = true,
                data = new
                {
                    // Identidad
                    dareeEst.Id,
                    Cedula = CedulaHelper.Normalize(dareeEst.Cedula),
                    dareeEst.Nombres,
                    dareeEst.Apellidos,
                    dareeEst.Sexo,
                    dareeEst.FechaNac,
                    dareeEst.Edad,
                    dareeEst.EstadoCivil,
                    dareeEst.Sangre,
                    dareeEst.Alergias,
                    dareeEst.Discapacidad,
                    dareeEst.DiscDesc,
                    // Académico
                    dareeEst.PnfId,
                    PnfNombre = pnf?.Nombre,
                    PnfColorHex = pnf?.ColorHex,
                    dareeEst.Trayecto,
                    dareeEst.Trimestre,
                    dareeEst.CodigoAlumno,
                    dareeEst.NumeroCarnet,
                    dareeEst.Estatus,
                    dareeEst.Modalidad,
                    dareeEst.ExpedienteEstado,
                    // Ubicación
                    dareeEst.NacPais,
                    dareeEst.NacEstado,
                    dareeEst.ResEstado,
                    dareeEst.ResMunicipio,
                    dareeEst.Direccion,
                    // Contacto
                    dareeEst.Correo,
                    dareeEst.Telefono,
                    dareeEst.TlfMov,
                    // Emergencia
                    dareeEst.RefNombre,
                    dareeEst.RefTelefono,
                    // Laboral
                    dareeEst.Trabaja,
                    dareeEst.EmpresaNombre,
                    dareeEst.MedioTraslado,
                    // Metadata
                    dareeEst.FechaRegistro,
                    dareeEst.SedeId
                }
            });
        }

        // ─── Inscripciones del Periodo Actual ────────────────────────

        /// <summary>
        /// Materias inscritas del estudiante en el periodo activo.
        /// GET /api/daree/mis-inscripciones
        /// Devuelve secciones con datos de UC, horario, docente.
        /// </summary>
        [HttpGet("mis-inscripciones")]
        [Authorize]
        public async Task<IActionResult> GetMisInscripciones()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioId == userId);
            if (estudiante == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado." });

            // Find Daree student by cedula
            var cedulaNorm = CedulaHelper.Normalize(estudiante.Cedula);
            var cedulaDaree = CedulaHelper.ToDareeFormat(estudiante.Cedula);

            var dareeEst = await _daree.Estudiantes
                .FirstOrDefaultAsync(e => e.Cedula == cedulaNorm
                                       || e.Cedula == cedulaDaree
                                       || e.Cedula == estudiante.Cedula);

            if (dareeEst == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado en Daree." });

            // Active period
            var periodoActivo = await _daree.Periodos.FirstOrDefaultAsync(p => p.Activo);
            if (periodoActivo == null)
                return NotFound(new { success = false, message = "No hay periodo activo." });

            // Get inscriptions for active period
            var inscripciones = await _daree.Inscripciones
                .Where(i => i.EstudianteId == dareeEst.Id && i.PeriodoId == periodoActivo.Id)
                .ToListAsync();

            // Enrich with section data
            var seccionIds = inscripciones.Select(i => i.SeccionId).Distinct().ToList();
            var secciones = await _daree.Secciones
                .Where(s => seccionIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id);

            // Get notes for these sections
            var notas = await _daree.InscripcionesNotas
                .Where(n => (n.EstudianteCedula == cedulaNorm
                          || n.EstudianteCedula == cedulaDaree)
                         && seccionIds.Contains(n.SeccionId))
                .ToDictionaryAsync(n => n.SeccionId);

            var result = inscripciones.Select(i =>
            {
                secciones.TryGetValue(i.SeccionId, out var sec);
                notas.TryGetValue(i.SeccionId, out var nota);
                return new
                {
                    i.Id,
                    i.SeccionId,
                    i.Estado,
                    i.FechaInscripcion,
                    // Section data
                    CodigoUc = sec?.CodigoUc ?? "N/A",
                    NombreUc = sec?.NombreUc ?? "N/A",
                    Trayecto = sec?.Trayecto,
                    Trimestre = sec?.Trimestre,
                    LetraSeccion = sec?.LetraSeccion,
                    DocenteNombre = sec?.DocenteNombre,
                    UnidadesCredito = sec?.UnidadesCredito ?? 0,
                    Horario = sec?.Horario,
                    Aula = sec?.Aula,
                    Edificio = sec?.Edificio,
                    EsPer = sec?.EsPer ?? false,
                    // Notes if available
                    C1 = nota?.C1,
                    C2 = nota?.C2,
                    C3 = nota?.C3,
                    C4 = nota?.C4,
                    Definitiva = nota?.Definitiva,
                    Asistencia = nota?.Asistencia,
                    EstatusMateria = nota?.EstatusMateria ?? "CURSANDO"
                };
            })
            .OrderBy(x => x.Trayecto)
            .ThenBy(x => x.Trimestre)
            .ThenBy(x => x.CodigoUc)
            .ToList();

            return Ok(new
            {
                success = true,
                periodo = periodoActivo.Codigo,
                estudianteId = dareeEst.Id,
                data = result,
                count = result.Count
            });
        }

        // ─── Historial Académico ─────────────────────────────────────

        /// <summary>
        /// Historial académico completo del estudiante con promedio ponderado.
        /// GET /api/daree/mi-historial
        /// </summary>
        [HttpGet("mi-historial")]
        [Authorize]
        public async Task<IActionResult> GetMiHistorial()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioId == userId);
            if (estudiante == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado." });

            // Find Daree student
            var cedulaNorm = CedulaHelper.Normalize(estudiante.Cedula);
            var cedulaDaree = CedulaHelper.ToDareeFormat(estudiante.Cedula);

            var dareeEst = await _daree.Estudiantes
                .FirstOrDefaultAsync(e => e.Cedula == cedulaNorm
                                       || e.Cedula == cedulaDaree
                                       || e.Cedula == estudiante.Cedula);

            if (dareeEst == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado en Daree." });

            var historial = await _daree.HistorialAcademico
                .Where(h => h.EstudianteId == dareeEst.Id)
                .OrderBy(h => h.Trayecto)
                .ThenBy(h => h.Trimestre)
                .ThenBy(h => h.CodigoUc)
                .ToListAsync();

            // Calculate weighted GPA
            var aprobadas = historial.Where(h => h.Condicion == "APROBADO" && h.NotaFinal.HasValue && h.UnidadesCredito.HasValue).ToList();
            var totalCreditos = aprobadas.Sum(h => h.UnidadesCredito!.Value);
            var sumaNotas = aprobadas.Sum(h => h.NotaFinal!.Value * h.UnidadesCredito!.Value);
            var promedioPonderado = totalCreditos > 0 ? Math.Round((double)(sumaNotas / totalCreditos), 2) : 0;

            var result = historial.Select(h => new
            {
                h.Id,
                h.CodigoUc,
                h.NombreUc,
                h.Trayecto,
                h.Trimestre,
                h.UnidadesCredito,
                h.NotaFinal,
                h.Condicion,
                h.Periodo,
                h.FechaCierre
            }).ToList();

            // Group by trayecto for structured view
            var porTrayecto = result
                .GroupBy(r => r.Trayecto ?? "Sin Trayecto")
                .Select(g => new
                {
                    Trayecto = g.Key,
                    Materias = g.ToList(),
                    CreditosTrayecto = g.Where(m => m.Condicion == "APROBADO").Sum(m => m.UnidadesCredito ?? 0)
                })
                .ToList();

            return Ok(new
            {
                success = true,
                estudianteId = dareeEst.Id,
                resumen = new
                {
                    TotalMaterias = historial.Count,
                    Aprobadas = historial.Count(h => h.Condicion == "APROBADO"),
                    Reprobadas = historial.Count(h => h.Condicion == "REPROBADO"),
                    CreditosAprobados = totalCreditos,
                    PromedioPonderado = promedioPonderado
                },
                porTrayecto,
                data = result,
                count = result.Count
            });
        }

        // ─── Directorio de Docentes ──────────────────────────────────

        /// <summary>
        /// Lista de docentes, opcionalmente filtrados por PNF.
        /// GET /api/daree/docentes?pnfId=3
        /// </summary>
        [HttpGet("docentes")]
        [Authorize]
        public async Task<IActionResult> GetDocentes([FromQuery] int? pnfId)
        {
            var query = _daree.Docentes.AsQueryable();

            if (pnfId.HasValue)
                query = query.Where(d => d.PnfId == pnfId.Value);

            var docentes = await query
                .Where(d => d.Activo == 1)
                .OrderBy(d => d.Apellidos)
                .ThenBy(d => d.Nombres)
                .Select(d => new
                {
                    d.Id,
                    Cedula = d.Cedula,
                    d.Nombres,
                    d.Apellidos,
                    NombreCompleto = d.Nombres + " " + d.Apellidos,
                    d.Correo,
                    d.Telefono,
                    d.Profesion,
                    d.Especialidad,
                    d.PnfId,
                    d.Estatus
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                data = docentes,
                count = docentes.Count
            });
        }

        /// <summary>
        /// Detalle de un docente con su carga académica del periodo activo.
        /// GET /api/daree/docente/{cedula}
        /// </summary>
        [HttpGet("docente/{cedula}")]
        [Authorize]
        public async Task<IActionResult> GetDocenteDetalle(string cedula)
        {
            var normalizada = CedulaHelper.Normalize(cedula);
            var dareeFormat = CedulaHelper.ToDareeFormat(cedula);

            var docente = await _daree.Docentes
                .FirstOrDefaultAsync(d => d.Cedula == normalizada
                                       || d.Cedula == dareeFormat
                                       || d.Cedula == cedula);

            if (docente == null)
                return NotFound(new { success = false, message = "Docente no encontrado." });

            // Active period
            var periodoActivo = await _daree.Periodos.FirstOrDefaultAsync(p => p.Activo);

            // Carga académica del docente: secciones asignadas
            var cargaQuery = _daree.Secciones
                .Where(s => s.DocenteCedula == docente.Cedula
                         || s.DocenteCedula == normalizada
                         || s.DocenteCedula == dareeFormat);

            if (periodoActivo != null)
                cargaQuery = cargaQuery.Where(s => s.PeriodoId == periodoActivo.Id);

            var carga = await cargaQuery
                .Select(s => new
                {
                    s.Id,
                    s.CodigoUc,
                    s.NombreUc,
                    s.Trayecto,
                    s.Trimestre,
                    s.LetraSeccion,
                    s.Aula,
                    s.Horario,
                    s.Inscritos,
                    s.Estado
                })
                .ToListAsync();

            // PNF name
            var pnf = docente.PnfId.HasValue
                ? await _daree.Pnfs.FirstOrDefaultAsync(p => p.Id == docente.PnfId.Value)
                : null;

            return Ok(new
            {
                success = true,
                data = new
                {
                    docente.Id,
                    Cedula = CedulaHelper.Normalize(docente.Cedula),
                    docente.Nombres,
                    docente.Apellidos,
                    docente.Correo,
                    docente.Telefono,
                    docente.Profesion,
                    docente.Especialidad,
                    docente.PnfId,
                    PnfNombre = pnf?.Nombre,
                    docente.Estatus
                },
                cargaAcademica = carga,
                periodo = periodoActivo?.Codigo,
                totalSecciones = carga.Count
            });
        }

        // ─── Asistencias del Estudiante ──────────────────────────────

        /// <summary>
        /// Asistencias del estudiante logueado, por sección.
        /// GET /api/daree/mis-asistencias?seccionId=SEC_2026_I_...
        /// Sin seccionId devuelve resumen por materia.
        /// </summary>
        [HttpGet("mis-asistencias")]
        [Authorize]
        public async Task<IActionResult> GetMisAsistencias([FromQuery] string? seccionId)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var estudiante = await _context.Estudiantes.FirstOrDefaultAsync(e => e.UsuarioId == userId);
            if (estudiante == null)
                return NotFound(new { success = false, message = "Estudiante no encontrado." });

            var cedulaNorm = CedulaHelper.Normalize(estudiante.Cedula);
            var cedulaDaree = CedulaHelper.ToDareeFormat(estudiante.Cedula);

            var query = _daree.Asistencias
                .Where(a => a.EstudianteCedula == cedulaNorm
                         || a.EstudianteCedula == cedulaDaree
                         || a.EstudianteCedula == estudiante.Cedula);

            if (!string.IsNullOrEmpty(seccionId))
            {
                // Detail: all attendance records for a specific section
                query = query.Where(a => a.SeccionId == seccionId);

                var registros = await query
                    .OrderByDescending(a => a.Fecha)
                    .Select(a => new
                    {
                        a.Id,
                        a.Fecha,
                        a.Estado,
                        a.Observacion
                    })
                    .ToListAsync();

                var total = registros.Count;
                var presentes = registros.Count(r => r.Estado == "PRESENTE");
                var ausentes = registros.Count(r => r.Estado == "AUSENTE");
                var justificadas = registros.Count(r => r.Estado == "JUSTIFICADO");
                var tardanzas = registros.Count(r => r.Estado == "TARDANZA");
                var porcentaje = total > 0
                    ? Math.Round((double)(presentes + justificadas) / total * 100, 1)
                    : 0;

                // Get section info
                var sec = await _daree.Secciones.FirstOrDefaultAsync(s => s.Id == seccionId);

                return Ok(new
                {
                    success = true,
                    seccionId,
                    nombreUc = sec?.NombreUc ?? "N/A",
                    resumen = new
                    {
                        TotalClases = total,
                        Presentes = presentes,
                        Ausentes = ausentes,
                        Justificadas = justificadas,
                        Tardanzas = tardanzas,
                        PorcentajeAsistencia = porcentaje
                    },
                    data = registros
                });
            }
            else
            {
                // Summary: group by section
                var todas = await query.ToListAsync();

                var seccionIds = todas.Select(a => a.SeccionId).Distinct().ToList();
                var secciones = await _daree.Secciones
                    .Where(s => seccionIds.Contains(s.Id))
                    .ToDictionaryAsync(s => s.Id);

                var resumen = seccionIds.Select(sid =>
                {
                    var registros = todas.Where(a => a.SeccionId == sid).ToList();
                    var total = registros.Count;
                    var presentes = registros.Count(r => r.Estado == "PRESENTE");
                    var justificadas = registros.Count(r => r.Estado == "JUSTIFICADO");
                    var porcentaje = total > 0
                        ? Math.Round((double)(presentes + justificadas) / total * 100, 1)
                        : 0;

                    secciones.TryGetValue(sid, out var sec);
                    return new
                    {
                        SeccionId = sid,
                        CodigoUc = sec?.CodigoUc ?? "N/A",
                        NombreUc = sec?.NombreUc ?? "N/A",
                        TotalClases = total,
                        Presentes = presentes,
                        Ausentes = registros.Count(r => r.Estado == "AUSENTE"),
                        Justificadas = justificadas,
                        Tardanzas = registros.Count(r => r.Estado == "TARDANZA"),
                        PorcentajeAsistencia = porcentaje
                    };
                })
                .OrderBy(r => r.NombreUc)
                .ToList();

                return Ok(new
                {
                    success = true,
                    data = resumen,
                    count = resumen.Count
                });
            }
        }

        // ─── Plan de Evaluación ──────────────────────────────────────

        /// <summary>
        /// Evaluaciones definidas para una sección (parciales, trabajos, etc.).
        /// GET /api/daree/evaluaciones/{seccionId}
        /// </summary>
        [HttpGet("evaluaciones/{seccionId}")]
        [Authorize]
        public async Task<IActionResult> GetEvaluaciones(string seccionId)
        {
            var evaluaciones = await _daree.Evaluaciones
                .Where(e => e.SeccionId == seccionId)
                .OrderBy(e => e.FechaEvaluacion)
                .Select(e => new
                {
                    e.Id,
                    e.Nombre,
                    e.Porcentaje,
                    e.FechaEvaluacion
                })
                .ToListAsync();

            // Get section info for context
            var sec = await _daree.Secciones.FirstOrDefaultAsync(s => s.Id == seccionId);
            var totalPorcentaje = evaluaciones.Sum(e => e.Porcentaje ?? 0);

            return Ok(new
            {
                success = true,
                seccionId,
                nombreUc = sec?.NombreUc ?? "N/A",
                codigoUc = sec?.CodigoUc ?? "N/A",
                docenteNombre = sec?.DocenteNombre,
                totalPorcentaje,
                data = evaluaciones,
                count = evaluaciones.Count
            });
        }
    }
}
