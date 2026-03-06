class Asistencia {
  final int idAsistencia;
  final int asignaturaId;
  final int estudianteId;
  final String fecha;
  final String codigoQR;

  Asistencia({
    required this.idAsistencia,
    required this.asignaturaId,
    required this.estudianteId,
    required this.fecha,
    required this.codigoQR,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      idAsistencia: json['idAsistencia'] ?? 0,
      asignaturaId: json['asignaturaId'] ?? 0,
      estudianteId: json['estudianteId'] ?? 0,
      fecha: json['fecha'] != null ? json['fecha'].toString() : '',
      codigoQR: json['codigoQR'] ?? '',
    );
  }
}
