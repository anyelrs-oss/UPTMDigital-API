using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;
using UPTMDigital.API.Data;
using UPTMDigital.API.Models;
using UglyToad.PdfPig;

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
        /// Recibe un archivo PDF e intenta extraer texto usando PdfPig e identificar evaluaciones.
        /// </summary>
        [HttpPost("extract-pdf")]
        public async Task<IActionResult> ExtractFromPdf(IFormFile file)
        {
            if (file == null || file.Length == 0) return BadRequest("No se proporcionó un archivo válido.");

            var extractedEvaluations = new List<EvaluacionDto>();

            try
            {
                using var stream = file.OpenReadStream();
                using var document = PdfDocument.Open(stream);

                var fullText = "";
                foreach (var page in document.GetPages())
                {
                    fullText += page.Text;
                }

                // Regex para buscar patrones comunes: Nombre + Porcentaje% + Fecha (dd/mm/aaaa o dd/mm)
                var matches = Regex.Matches(fullText, @"([a-zA-ZñÑáéíóúÁÉÍÓÚ\s]{5,30})\s+(\d{1,2})%\s+(\d{1,2}/\d{1,2}(?:/\d{4})?)");

                foreach (Match match in matches)
                {
                    var pond = decimal.Parse(match.Groups[2].Value);
                    if (pond > 0 && pond <= 100)
                    {
                        extractedEvaluations.Add(new EvaluacionDto
                        {
                            Nombre = match.Groups[1].Value.Trim(),
                            Ponderacion = pond,
                            FechaStr = match.Groups[3].Value
                        });
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
                return StatusCode(500, $"Error procesando archivo PDF: {ex.Message}");
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
