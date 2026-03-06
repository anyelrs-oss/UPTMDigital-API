class Inscripcion {
  final int idInscripcion;
  final int estudianteId;
  final int asignaturaId;
  final String periodo;
  final String estado;

  Inscripcion({
    required this.idInscripcion,
    required this.estudianteId,
    required this.asignaturaId,
    required this.periodo,
    required this.estado,
  });

  factory Inscripcion.fromJson(Map<String, dynamic> json) {
    return Inscripcion(
      idInscripcion: json['idInscripcion'] ?? 0,
      estudianteId: json['estudianteId'] ?? 0,
      asignaturaId: json['asignaturaId'] ?? 0,
      periodo: json['periodo'] ?? '',
      estado: json['estado'] ?? '',
    );
  }
}
