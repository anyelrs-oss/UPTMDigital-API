class Profesor {
  final int idProfesor;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String correoInstitucional;
  final String departamento;

  Profesor({
    required this.idProfesor,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.correoInstitucional,
    required this.departamento,
  });

  factory Profesor.fromJson(Map<String, dynamic> json) {
    return Profesor(
      idProfesor: json['idProfesor'] ?? 0,
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      correoInstitucional: json['correoInstitucional'] ?? '',
      departamento: json['departamento'] ?? '',
    );
  }
}
