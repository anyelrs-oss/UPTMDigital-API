class Anuncio {
  final int idAnuncio;
  final String titulo;
  final String contenido;
  final String fechaPublicacion;
  final String? autor;

  Anuncio({
    required this.idAnuncio,
    required this.titulo,
    required this.contenido,
    required this.fechaPublicacion,
    this.autor,
  });

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      idAnuncio: json['idAnuncio'],
      titulo: json['titulo'],
      contenido: json['contenido'],
      fechaPublicacion: json['fechaPublicacion'],
      autor: json['autor'],
    );
  }
}
