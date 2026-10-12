class DareePensumUc {
  final int id;
  final String trayecto;
  final String trimestre;
  final String codigoUc;
  final String nombreUc;
  final int unidadesCredito;
  final String tipoUc;
  final int horasAcademicas;
  final int notaMinima;
  final double asistenciaMinima;
  final bool permitePer;

  DareePensumUc({
    required this.id,
    required this.trayecto,
    required this.trimestre,
    required this.codigoUc,
    required this.nombreUc,
    required this.unidadesCredito,
    required this.tipoUc,
    required this.horasAcademicas,
    required this.notaMinima,
    required this.asistenciaMinima,
    required this.permitePer,
  });

  factory DareePensumUc.fromJson(Map<String, dynamic> json) {
    return DareePensumUc(
      id: json['id'] ?? 0,
      trayecto: json['trayecto'] ?? '',
      trimestre: json['trimestre'] ?? '',
      codigoUc: json['codigoUc'] ?? '',
      nombreUc: json['nombreUc'] ?? '',
      unidadesCredito: json['unidadesCredito'] ?? 0,
      tipoUc: json['tipoUc'] ?? 'REGULAR',
      horasAcademicas: json['horasAcademicas'] ?? 0,
      notaMinima: json['notaMinima'] ?? 12,
      asistenciaMinima: (json['asistenciaMinima'] ?? 75.0).toDouble(),
      permitePer: json['permitePer'] ?? true,
    );
  }
}
