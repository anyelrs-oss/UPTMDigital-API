class Asignatura {
  final int idAsignatura;
  final String codigo;
  final String nombre;
  final int creditos;
  final int? semestreId;
  final String departamento;
  final int? profesorId;
  final int? carreraId;
  final String semestreNombre;

  Asignatura({
    required this.idAsignatura,
    required this.codigo,
    required this.nombre,
    required this.creditos,
    this.semestreId,
    required this.departamento,
    this.profesorId,
    this.carreraId,
    this.semestreNombre = '',
  });

  factory Asignatura.fromJson(Map<String, dynamic> json) {
    String sem = '';
    if (json['semestre'] is Map) {
      sem = json['semestre']['nombre']?.toString() ?? '';
    } else if (json['semestreNombre'] != null) {
      sem = json['semestreNombre'].toString();
    } else if (json['semestre'] != null) {
      sem = json['semestre'].toString();
    }

    return Asignatura(
      idAsignatura: json['idAsignatura'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      creditos: json['creditos'] ?? 0,
      semestreId: json['semestreId'],
      departamento: json['departamento'] ?? '',
      profesorId: json['profesorId'],
      carreraId: json['carreraId'],
      semestreNombre: sem,
    );
  }
}
