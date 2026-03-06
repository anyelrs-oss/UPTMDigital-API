class Mensaje {
  final int idMensaje;
  final int asignaturaId;
  final String content;
  final String fechaEnvio;
  final String emisorNombre;

  Mensaje({
    required this.idMensaje,
    required this.asignaturaId,
    required this.content,
    required this.fechaEnvio,
    required this.emisorNombre,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      idMensaje: json['idMensaje'],
      asignaturaId: json['asignaturaId'],
      content: json['contenido'],
      fechaEnvio: json['fechaEnvio'],
      emisorNombre: json['emisorNombre'],
    );
  }
}
