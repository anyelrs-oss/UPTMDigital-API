class Constancia {
  final int idConstancia;
  final int estudianteId;
  final String tipoConstancia;
  final String estado;
  final String fechaSolicitud;
  final String codigoQR;

  Constancia({
    required this.idConstancia,
    required this.estudianteId,
    required this.tipoConstancia,
    required this.estado,
    required this.fechaSolicitud,
    required this.codigoQR,
  });

  factory Constancia.fromJson(Map<String, dynamic> json) {
    return Constancia(
      idConstancia: json['idConstancia'] ?? 0,
      estudianteId: json['estudianteId'] ?? 0,
      tipoConstancia: json['tipoConstancia'] ?? '',
      estado: json['estado'] ?? '',
      fechaSolicitud: json['fechaSolicitud'] != null ? json['fechaSolicitud'].toString() : '',
      codigoQR: json['codigoQR'] ?? '',
    );
  }
}
