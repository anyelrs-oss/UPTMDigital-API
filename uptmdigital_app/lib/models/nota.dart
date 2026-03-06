class Nota {
  final int idNota;
  final int asignaturaId;
  final int estudianteId;
  final double calificacion;
  final String codigoQR;
  final int? profesorId;

  Nota({
    required this.idNota,
    required this.asignaturaId,
    required this.estudianteId,
    required this.calificacion,
    required this.codigoQR,
    this.profesorId, // Optional, from API
  });

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      idNota: json['idNota'] ?? 0,
      asignaturaId: json['asignaturaId'] ?? 0,
      estudianteId: json['estudianteId'] ?? 0,
      calificacion: (json['calificacion'] ?? 0).toDouble(),
      codigoQR: json['codigoQR'] ?? '',
      profesorId: json['profesorId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idNota': idNota,
      'asignaturaId': asignaturaId,
      'estudianteId': estudianteId,
      'calificacion': calificacion,
      'codigoQR': codigoQR,
      'profesorId': profesorId,
    };
  }
}
