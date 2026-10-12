class DareePeriodo {
  final int id;
  final String? codigo;
  final String? nombre;
  final String? descripcion;
  final String? fechaInicio;
  final String? fechaFin;
  final String estatus;
  final String fase;
  final bool bloqueaInscripciones;
  final bool bloqueaNotas;

  DareePeriodo({
    required this.id,
    this.codigo,
    this.nombre,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    required this.estatus,
    required this.fase,
    required this.bloqueaInscripciones,
    required this.bloqueaNotas,
  });

  factory DareePeriodo.fromJson(Map<String, dynamic> json) {
    return DareePeriodo(
      id: json['id'] ?? 0,
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      fechaInicio: json['fechaInicio'],
      fechaFin: json['fechaFin'],
      estatus: json['estatus'] ?? 'ABIERTO',
      fase: json['fase'] ?? 'PLANIFICACION',
      bloqueaInscripciones: json['bloqueaInscripciones'] ?? false,
      bloqueaNotas: json['bloqueaNotas'] ?? false,
    );
  }
}
