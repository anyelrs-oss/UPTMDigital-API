class Anuncio {
  final int idAnuncio;
  final String titulo;
  final String contenido;
  final String fechaPublicacion;
  final String? autor;
  final int? usuarioId;

  Anuncio({
    required this.idAnuncio,
    required this.titulo,
    required this.contenido,
    required this.fechaPublicacion,
    this.autor,
    this.usuarioId,
  });

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      idAnuncio: json['idAnuncio'],
      titulo: json['titulo'],
      contenido: json['contenido'],
      fechaPublicacion: json['fechaPublicacion'],
      autor: json['autor'],
      usuarioId: json['usuarioId'],
    );
  }
}
