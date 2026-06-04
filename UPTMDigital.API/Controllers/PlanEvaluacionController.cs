using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;
using System.Text.RegularExpressions;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;

namespace UPTMDigital.API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class PlanEvaluacionController : ControllerBase
    {
        private readonly UPTMDigitalContext _context;

        public PlanEvaluacionController(UPTMDigitalContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Recibe un archivo PDF, extrae texto e intenta identificar evaluaciones.
        /// Formato esperado en el PDF: "Nombre de actividad ... 20% ... dd/mm/yyyy"
        /// </summary>
        [HttpPost("extract-pdf")]
        public async Task<IActionResult> ExtractFromPdf(IFormFile file)
        {
            if (file == null || file.Length == 0) return BadRequest("No se proporcionó un archivo válido.");
            if (!file.FileName.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase)) return BadRequest("El archivo debe ser un PDF.");

            var extractedEvaluations = new List<EvaluacionDto>();

            try
            {
                using (var stream = file.OpenReadStream())
                using (var document = PdfDocument.Open(stream))
                {
                    foreach (var page in document.GetPages())
                    {
                        var text = page.Text;
                        // Regex para buscar patrones comunes: Nombre (Texto) + Porcentaje (Número%) + Fecha (dd/mm/aaaa)
                        // Ej: "Examen Parcial 25% 15/06/2024"
                        var matches = Regex.Matches(text, @"([a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+)\s+(\d{1,2})%\s+(\d{1,2}/\d{1,2}/\d{4})");

                        foreach (Match match in matches)
                        {
                            extractedEvaluations.Add(new EvaluacionDto
                            {
                                Nombre = match.Groups[1].Value.Trim(),
                                Ponderacion = decimal.Parse(match.Groups[2].Value),
                                FechaStr = match.Groups[3].Value
                            });
                        }
                    }
                }

                if (extractedEvaluations.Count == 0)
                {
                    return Ok(new {
                        message = "No se detectaron tablas de evaluación automáticas. Se requiere carga manual o formato más claro.",
                        data = new List<EvaluacionDto>()
                    });
                }

                return Ok(new { message = "Extracción exitosa", data = extractedEvaluations });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error procesando PDF: {ex.Message}");
            }
        }

        public class EvaluacionDto
        {
            public string Nombre { get; set; } = null!;
            public decimal Ponderacion { get; set; }
            public string FechaStr { get; set; } = null!;
        }
    }
}
