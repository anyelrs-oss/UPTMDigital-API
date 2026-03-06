class Asignatura {
  final int idAsignatura;
  final String codigo;
  final String nombre;
  final int creditos;
  final int semestre;
  final String departamento;
  final int? profesorId;

  Asignatura({
    required this.idAsignatura,
    required this.codigo,
    required this.nombre,
    required this.creditos,
    required this.semestre,
    required this.departamento,
    this.profesorId,
  });

  factory Asignatura.fromJson(Map<String, dynamic> json) {
    return Asignatura(
      idAsignatura: json['idAsignatura'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      creditos: json['creditos'] ?? 0,
      semestre: json['semestre'] ?? 1,
      departamento: json['departamento'] ?? '',
      profesorId: json['profesorId'],
    );
  }
}
