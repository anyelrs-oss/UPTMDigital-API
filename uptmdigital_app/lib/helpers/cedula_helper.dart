/// Utilidades para normalizar cédulas entre UPTM y Daree.
///
/// UPTM: "29652018" (solo números)
/// Daree: "V-29652018" (con prefijo de nacionalidad)
class CedulaHelper {
  /// Extrae solo dígitos: "V-29652018" → "29652018"
  static String normalize(String? cedula) {
    if (cedula == null || cedula.trim().isEmpty) return '';

    var cleaned = cedula.trim()
        .replaceAll('-', '')
        .replaceAll('.', '')
        .replaceAll(' ', '');

    // Remove nationality prefix (V, E, J, G, P, etc.)
    if (cleaned.length > 1 &&
        RegExp(r'^[A-Za-z]').hasMatch(cleaned) &&
        RegExp(r'\d').hasMatch(cleaned[1])) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }

  /// Convierte al formato Daree: "29652018" → "V-29652018"
  static String toDareeFormat(String? cedula, {String prefix = 'V'}) {
    if (cedula == null || cedula.trim().isEmpty) return '';

    final trimmed = cedula.trim();

    // Already has prefix?
    if (trimmed.length > 2 &&
        RegExp(r'^[A-Za-z]').hasMatch(trimmed) &&
        trimmed[1] == '-') {
      return trimmed;
    }

    return '$prefix-${normalize(trimmed)}';
  }

  /// Formato display: "V-29.652.018"
  static String toDisplayFormat(String? cedula, {String prefix = 'V'}) {
    final digits = normalize(cedula);
    if (digits.isEmpty) return '';

    // Add thousand separators
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return '$prefix-$buffer';
  }

  /// Compara dos cédulas ignorando formato
  static bool areEqual(String? cedula1, String? cedula2) {
    return normalize(cedula1) == normalize(cedula2);
  }
}
