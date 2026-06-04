class Anuncio {
  final int idAnuncio;
  final String titulo;
  final String contenido;
  final String fechaPublicacion;
  final String? autor;
  final int? usuarioId;
  final String prioridad;

  Anuncio({
    required this.idAnuncio,
    required this.titulo,
    required this.contenido,
    required this.fechaPublicacion,
    this.autor,
    this.usuarioId,
    this.prioridad = "Normal",
  });

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      idAnuncio: json['idAnuncio'] ?? 0,
      titulo: json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      fechaPublicacion: json['fechaPublicacion'] ?? '',
      autor: json['autor'],
      usuarioId: json['usuarioId'],
      prioridad: json['prioridad'] ?? 'Normal',
    );
  }
}
