class Mensaje {
  final int idMensaje;
  final int asignaturaId;
  final String content;
  final String fechaEnvio;
  final String emisorNombre;
  final int? usuarioId;
  final String? imageUrl;
  final String tipo; // 'Texto' o 'Imagen'

  Mensaje({
    required this.idMensaje,
    required this.asignaturaId,
    required this.content,
    required this.fechaEnvio,
    required this.emisorNombre,
    this.usuarioId,
    this.imageUrl,
    this.tipo = 'Texto',
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      idMensaje: json['idMensaje'] ?? json['IdMensaje'],
      asignaturaId: json['asignaturaId'] ?? json['AsignaturaId'] ?? 0,
      content: json['contenido'] ?? json['Contenido'] ?? '',
      fechaEnvio: json['fechaEnvio'] ?? json['FechaEnvio'] ?? '',
      emisorNombre: json['emisorNombre'] ?? json['EmisorNombre'] ?? '',
      usuarioId: json['usuarioId'] ?? json['UsuarioId'],
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      tipo: json['tipoChat'] ?? json['TipoChat'] ?? 'Texto',
    );
  }
}
