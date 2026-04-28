class Inscripcion {
  final int idInscripcion;
  final int estudianteId;
  final int asignaturaId;
  final int? periodoId;
  final String estado;
  final String periodoNombre;

  Inscripcion({
    required this.idInscripcion,
    required this.estudianteId,
    required this.asignaturaId,
    this.periodoId,
    required this.estado,
    this.periodoNombre = '',
  });

  factory Inscripcion.fromJson(Map<String, dynamic> json) {
    String per = '';
    if (json['periodo'] is Map) {
      per = json['periodo']['nombre']?.toString() ?? '';
    } else if (json['periodoNombre'] != null) {
      per = json['periodoNombre'].toString();
    } else if (json['periodo'] != null) {
      per = json['periodo'].toString();
    }

    return Inscripcion(
      idInscripcion: json['idInscripcion'] ?? 0,
      estudianteId: json['estudianteId'] ?? 0,
      asignaturaId: json['asignaturaId'] ?? 0,
      periodoId: json['periodoId'],
      estado: json['estado'] ?? '',
      periodoNombre: per,
    );
  }
}
