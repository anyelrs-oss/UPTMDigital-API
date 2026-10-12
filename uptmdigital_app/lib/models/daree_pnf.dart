class DareePnf {
  final int id;
  final String codigo;
  final String nombre;
  final String? colorHex;

  DareePnf({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.colorHex,
  });

  factory DareePnf.fromJson(Map<String, dynamic> json) {
    return DareePnf(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      colorHex: json['colorHex'],
    );
  }
}
