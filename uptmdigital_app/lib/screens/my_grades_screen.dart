import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class MyGradesScreen extends StatefulWidget {
  const MyGradesScreen({super.key});

  @override
  State<MyGradesScreen> createState() => _MyGradesScreenState();
}

class _MyGradesScreenState extends State<MyGradesScreen> {
  List<dynamic> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getStudentGradesMe();
    if (mounted) {
      setState(() {
        _grades = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Calificaciones"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGrades,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grades.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGrades,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _grades.length,
                    itemBuilder: (context, index) {
                      final grade = _grades[index];
                      return _buildGradeCard(grade);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Aún no tienes notas registradas\nen este periodo.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(dynamic grade) {
    double calificacion = (grade['calificacion'] as num).toDouble();

    // Lógica de "Semáforo" sugerida
    Color colorEstado;
    String textoEstado;
    IconData iconoEstado;

    if (calificacion >= 18) {
      colorEstado = Colors.amber.shade700; // Dorado para Excelencia
      textoEstado = "EXCELENTE";
      iconoEstado = Icons.stars;
    } else if (calificacion >= 10) {
      colorEstado = Colors.green.shade600; // Verde para Aprobado
      textoEstado = "APROBADO";
      iconoEstado = Icons.check_circle_outline;
    } else {
      colorEstado = Colors.red.shade600; // Rojo para Reprobado
      textoEstado = "REPROBADO";
      iconoEstado = Icons.error_outline;
    }

    return InstitutionalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: colorEstado, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: colorEstado.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  calificacion.toInt().toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.black,
                    color: colorEstado,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade['asignaturaNombre'] ?? "Asignatura",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "Prof: ${grade['profesorNombre']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(iconoEstado, size: 14, color: colorEstado),
                      const SizedBox(width: 4),
                      Text(
                        textoEstado,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorEstado,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
