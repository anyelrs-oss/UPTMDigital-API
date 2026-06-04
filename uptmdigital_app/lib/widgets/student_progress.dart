import 'package:flutter/material.dart';
import 'package:uptmdigital_app/widgets/double_progress_ring.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'dart:convert';
import 'package:uptmdigital_app/theme.dart';

class StudentProgress extends StatefulWidget {
  final int studentId;
  const StudentProgress({super.key, required this.studentId});

  @override
  State<StudentProgress> createState() => _StudentProgressState();
}

class _StudentProgressState extends State<StudentProgress> {
  double _progress = 0.0;
  int _creditsPassed = 0;
  final int _totalCredits = 180; // Hardcoded for prototype
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  Future<void> _calculateProgress() async {
    final api = ApiService();
    
    // Intentar cargar de caché primero
    final cachedGrades = await api.storage.read(key: 'cached_my_grades');
    if (cachedGrades != null && mounted) {
      _processGrades(jsonDecode(cachedGrades));
    }

    // Cargar de red
    final grades = await api.getStudentGradesMe();
    if (mounted) {
      _processGrades(grades);
      setState(() => _isLoading = false);
    }
  }

  void _processGrades(List<dynamic> grades) {
    int passed = 0;
    for (var nota in grades) {
      final grade = double.tryParse(nota['calificacion'].toString()) ?? 0.0;
      if (grade >= 10) {
        passed += 3; // Estimación de 3 créditos por materia
      }
    }
    if (mounted) {
      setState(() {
        _creditsPassed = passed;
        _progress = (_creditsPassed / _totalCredits).clamp(0.0, 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DoubleProgressRing(
            careerProgress: _progress,
            periodProgress: 0.65, // Mock period progress
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Carrera", "${(_progress * 100).toInt()}%", AppTheme.primary),
              _buildStatItem("Trimestre", "65%", AppTheme.secondary),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            "Créditos Aprobados: $_creditsPassed / $_totalCredits",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
