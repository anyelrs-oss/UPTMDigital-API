class Horario {
  final int idHorario;
  final int asignaturaId;
  final String dia;
  final String horaInicio;
  final String horaFin;
  final String aula;

  Horario({
    required this.idHorario,
    required this.asignaturaId,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.aula,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      idHorario: json['idHorario'],
      asignaturaId: json['asignaturaId'],
      dia: json['dia'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
      aula: json['aula'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idHorario': idHorario,
      'asignaturaId': asignaturaId,
      'dia': dia,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'aula': aula,
    };
  }
}
