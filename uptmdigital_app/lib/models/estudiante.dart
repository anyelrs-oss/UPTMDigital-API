class Estudiante {
  final int idEstudiante;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String correoInstitucional;
  final String carrera;

  Estudiante({
    required this.idEstudiante,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.correoInstitucional,
    required this.carrera,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      idEstudiante: json['idEstudiante'] ?? 0,
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      correoInstitucional: json['correoInstitucional'] ?? '',
      carrera: json['carrera'] ?? '',
    );
  }
}
