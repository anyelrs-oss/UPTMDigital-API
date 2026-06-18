import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/screens/academic_hierarchy_screen.dart';
import 'package:uptmdigital_app/screens/horarios_screen.dart';
import 'package:uptmdigital_app/screens/notas_screen.dart';
import 'package:uptmdigital_app/screens/asistencias_screen.dart';

import 'package:uptmdigital_app/screens/evaluar_screen.dart';
import 'package:uptmdigital_app/screens/plan_evaluacion_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final dynamic carrera;
  final dynamic semestre;
  final AcademicTarget target;
  final int? professorId;

  const SubjectSelectionScreen({
    super.key,
    required this.carrera,
    required this.semestre,
    required this.target,
    this.professorId,
  });

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  List<dynamic> _asignaturas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);

    // Obtenemos todas las asignaturas
    final all = await ApiService().getAsignaturas();

    if (mounted) {
      setState(() {
        if (widget.professorId != null && widget.carrera == null) {
          // Flujo simplificado para profesor: No filtrar por carrera/semestre específico si no vienen
          _asignaturas = all.where((a) => a['profesorId'] == widget.professorId).toList();
        } else {
          // Flujo estándar (Admin o selección jerárquica)
          _asignaturas = all.where((a) =>
            a['carreraId'] == widget.carrera?['idCarrera'] &&
            a['semestreId'] == widget.semestre?['idSemestre']
          ).toList();

          if (widget.professorId != null) {
            _asignaturas = _asignaturas.where((a) => a['profesorId'] == widget.professorId).toList();
          }
        }

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.semestre?['nombre'] ?? "Mis Materias";
    final String subtitle = widget.carrera?['nombre'] ?? "Selección Directa";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _asignaturas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        "No hay materias registradas para este trimestre.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _asignaturas.length,
                  itemBuilder: (context, index) {
                    final a = _asignaturas[index];
                    return InstitutionalCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.book, color: AppTheme.primary, size: 20),
                        ),
                        title: Text(a['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Código: ${a['codigo'] ?? 'N/A'}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _onSubjectTap(a),
                      ),
                    );
                  },
                ),
    );
  }

  void _onSubjectTap(dynamic asignatura) {
    final id = asignatura['idAsignatura'];
    final nombre = asignatura['nombre'];

    switch (widget.target) {
      case AcademicTarget.horarios:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => HorariosScreen(asignaturaId: id, asignaturaNombre: nombre, isAdmin: true)
        ));
        break;
      case AcademicTarget.notas:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => NotasScreen(asignaturaId: id, asignaturaNombre: nombre)
        ));
        break;
      case AcademicTarget.asistencias:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AsistenciasScreen(asignaturaId: id, asignaturaNombre: nombre)
        ));
        break;
      case AcademicTarget.evaluar:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => EvaluarScreen(asignaturaId: id, asignaturaNombre: nombre)
        ));
        break;
      case AcademicTarget.planificacion:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PlanEvaluacionScreen(asignaturaId: id, asignaturaNombre: nombre)
        ));
        break;
    }
  }
}
