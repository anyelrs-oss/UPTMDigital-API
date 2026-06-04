class Estudiante {
  final int idEstudiante;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String correoInstitucional;
  final int? usuarioId;
  final int? carreraId;
  final String carreraNombre;
  final String? telefono;
  final String? profileImageUrl;

  Estudiante({
    required this.idEstudiante,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.correoInstitucional,
    this.usuarioId,
    this.carreraId,
    this.carreraNombre = '',
    this.telefono,
    this.profileImageUrl,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    // carrera can be a nested object { nombre: "..." } or null
    String carrera = '';
    if (json['carrera'] is Map) {
      carrera = json['carrera']['nombre'] ?? '';
    } else if (json['carreraNombre'] is String) {
      carrera = json['carreraNombre'];
    }

    return Estudiante(
      idEstudiante: json['idEstudiante'] ?? 0,
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      correoInstitucional: json['correoInstitucional'] ?? '',
      usuarioId: json['usuarioId'],
      carreraId: json['carreraId'],
      carreraNombre: carrera,
      telefono: json['telefono'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
