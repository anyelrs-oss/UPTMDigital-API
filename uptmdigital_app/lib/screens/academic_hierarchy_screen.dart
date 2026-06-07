import 'package:flutter/material.dart';
import 'package:uptmdigital_app/screens/subject_selection_screen.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

enum AcademicTarget { notas, horarios, asistencias }

class AcademicHierarchyScreen extends StatefulWidget {
  final AcademicTarget target;
  const AcademicHierarchyScreen({super.key, required this.target});

  @override
  State<AcademicHierarchyScreen> createState() => _AcademicHierarchyScreenState();
}

class _AcademicHierarchyScreenState extends State<AcademicHierarchyScreen> {
  List<dynamic> _carreras = [];
  List<dynamic> _semestres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final carreras = await ApiService.instance.getCarreras();
    final semestres = await ApiService.instance.getSemestres();
    if (mounted) {
      setState(() {
        _carreras = carreras;
        _semestres = semestres;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "Gestión Académica";
    if (widget.target == AcademicTarget.notas) title = "Selección de Carrera (Notas)";
    if (widget.target == AcademicTarget.horarios) title = "Selección de Carrera (Horarios)";
    if (widget.target == AcademicTarget.asistencias) title = "Selección de Carrera (Asistencias)";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _carreras.length,
              itemBuilder: (context, index) {
                final c = _carreras[index];
                return InstitutionalCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.account_balance, color: Colors.white, size: 20),
                    ),
                    title: Text(c['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTrimestres(c),
                  ),
                );
              },
            ),
    );
  }

  void _showTrimestres(dynamic carrera) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuarterSelectionScreen(
          carrera: carrera,
          semestres: _semestres,
          target: widget.target,
        ),
      ),
    );
  }
}

class QuarterSelectionScreen extends StatelessWidget {
  final dynamic carrera;
  final List<dynamic> semestres;
  final AcademicTarget target;

  const QuarterSelectionScreen({
    super.key,
    required this.carrera,
    required this.semestres,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${carrera['nombre']} - Trimestres")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: semestres.length,
        itemBuilder: (context, index) {
          final s = semestres[index];
          return InstitutionalCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                child: Text("${index + 1}", style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
              ),
              title: Text(s['nombre']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToSubjects(context, s),
            ),
          );
        },
      ),
    );
  }

  void _navigateToSubjects(BuildContext context, dynamic semestre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectSelectionScreen(
          carrera: carrera,
          semestre: semestre,
          target: target,
        ),
      ),
    );
  }
}
