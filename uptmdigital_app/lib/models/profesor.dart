class Profesor {
  final int idProfesor;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String correoInstitucional;
  final String departamento;
  final int? usuarioId;
  final String? profileImageUrl;
  final String? telefono;

  Profesor({
    required this.idProfesor,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.correoInstitucional,
    required this.departamento,
    this.usuarioId,
    this.profileImageUrl,
    this.telefono,
  });

  factory Profesor.fromJson(Map<String, dynamic> json) {
    return Profesor(
      idProfesor: json['idProfesor'] ?? 0,
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      correoInstitucional: json['correoInstitucional'] ?? '',
      departamento: json['departamento'] ?? '',
      usuarioId: json['usuarioId'],
      profileImageUrl: json['profileImageUrl'],
      telefono: json['telefono'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idProfesor': idProfesor,
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'correoInstitucional': correoInstitucional,
      'departamento': departamento,
      'usuarioId': usuarioId,
      'profileImageUrl': profileImageUrl,
      'telefono': telefono,
    };
  }
}
