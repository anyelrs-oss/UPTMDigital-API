import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';

class UpcomingEvaluations extends StatefulWidget {
  final int studentId;
  const UpcomingEvaluations({super.key, required this.studentId});

  @override
  State<UpcomingEvaluations> createState() => _UpcomingEvaluationsState();
}

class _UpcomingEvaluationsState extends State<UpcomingEvaluations> {
  List<dynamic> _evaluaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluaciones();
  }

  Future<void> _loadEvaluaciones() async {
    // Para el prototipo, cargamos inscripciones y luego evaluaciones de esas materias
    final inscripciones = await ApiService().getStudentInscripcionesMe();
    List<dynamic> allEval = [];

    for (var ins in inscripciones) {
      final evals = await ApiService().getEvaluaciones(ins['asignaturaId']);
      allEval.addAll(evals.map((e) => {...e, 'asignatura': ins['asignatura']}));
    }

    // Filtrar solo las futuras y ordenar
    allEval = allEval.where((e) => DateTime.parse(e['fechaEvaluacion']).isAfter(DateTime.now())).toList();
    allEval.sort((a, b) => a['fechaEvaluacion'].compareTo(b['fechaEvaluacion']));

    if (mounted) {
      setState(() {
        _evaluaciones = allEval.take(3).toList(); // Mostrar top 3
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_evaluaciones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No hay evaluaciones próximas.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: _evaluaciones.map((e) => _buildEvalItem(e)).toList(),
    );
  }

  Widget _buildEvalItem(dynamic e) {
    final fecha = DateTime.parse(e['fechaEvaluacion']);
    final diff = fecha.difference(DateTime.now()).inDays;

    return ListTile(
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: diff <= 3 ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${fecha.day}", style: TextStyle(fontWeight: FontWeight.bold, color: diff <= 3 ? Colors.red : Colors.blue)),
            Text(_getMonth(fecha.month), style: TextStyle(fontSize: 10, color: diff <= 3 ? Colors.red : Colors.blue)),
          ],
        ),
      ),
      title: Text(e['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(e['asignatura']),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text("${e['ponderacion']}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _getMonth(int m) {
    const months = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"];
    return months[m - 1];
  }
}
