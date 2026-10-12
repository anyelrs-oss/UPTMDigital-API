namespace UPTMDigital.API.Helpers
{
    /// <summary>
    /// Utilidades para normalizar cédulas entre diferentes formatos.
    /// 
    /// UPTM API (PostgreSQL): "29652018" (solo números)
    /// Daree (MariaDB): "V-29652018" (con prefijo de nacionalidad)
    /// 
    /// Este helper permite convertir entre ambos formatos para cruzar datos.
    /// </summary>
    public static class CedulaHelper
    {
        /// <summary>
        /// Extrae solo los dígitos de una cédula (quita V-, E-, prefijos, guiones, espacios).
        /// "V-29652018" → "29652018"
        /// "29652018" → "29652018"
        /// "E-84123456" → "84123456"
        /// </summary>
        public static string Normalize(string? cedula)
        {
            if (string.IsNullOrWhiteSpace(cedula))
                return string.Empty;

            // Remove common prefixes and separators
            var cleaned = cedula.Trim()
                .Replace("-", "")
                .Replace(".", "")
                .Replace(" ", "");

            // Remove nationality prefix (V, E, J, G, P, etc.)
            if (cleaned.Length > 1 && char.IsLetter(cleaned[0]) && char.IsDigit(cleaned[1]))
            {
                cleaned = cleaned[1..];
            }

            return cleaned;
        }

        /// <summary>
        /// Convierte una cédula plain al formato Daree: "29652018" → "V-29652018"
        /// Si ya tiene prefijo, la retorna tal cual.
        /// </summary>
        public static string ToDareeFormat(string? cedula, string prefix = "V")
        {
            if (string.IsNullOrWhiteSpace(cedula))
                return string.Empty;

            var trimmed = cedula.Trim();

            // Already has prefix?
            if (trimmed.Length > 2 && char.IsLetter(trimmed[0]) && trimmed[1] == '-')
                return trimmed;

            // Add prefix
            var digits = Normalize(trimmed);
            return $"{prefix}-{digits}";
        }

        /// <summary>
        /// Convierte una cédula al formato UPTM (solo dígitos): "V-29652018" → "29652018"
        /// </summary>
        public static string ToUptmFormat(string? cedula)
        {
            return Normalize(cedula);
        }

        /// <summary>
        /// Compara dos cédulas ignorando formato.
        /// "V-29652018" == "29652018" → true
        /// </summary>
        public static bool AreEqual(string? cedula1, string? cedula2)
        {
            return Normalize(cedula1) == Normalize(cedula2);
        }
    }
}
