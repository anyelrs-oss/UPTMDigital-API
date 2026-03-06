import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';

class StudentProgress extends StatefulWidget {
  final int studentId;
  const StudentProgress({Key? key, required this.studentId}) : super(key: key);

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
    // In a real app, we would fetch detailed "Kardex" or "Record Academico"
    // Here we will reuse getNotas() (which returns all grades) and filter/count client-side 
    // This is not efficient for production but fine for prototype given API constraints.
    // However, getNotas returns ALL notas of ALL students if admin, or filtered if we implement filter in backend.
    // The current getNotas returns ALL. This is bad for privacy/performance but consistent with current state.
    // A better approach: Add getStudentGrades endpoint. 
    // For now, I'll assumme getNotas is what we have or I'll implement a quick helper in ApiService if needed.
    // Wait, getNotas is generic. Let's use it and filter by widget.studentId.
    
    final notas = await ApiService().getNotas();
    int passed = 0;
    
    // Naively filter for this student and >= 10
    // Note: getNotas returns dynamic list.
    for (var nota in notas) {
      if (nota['estudianteId'] == widget.studentId) {
        // Assume 'calificacion' is double or int
        final grade = double.tryParse(nota['calificacion'].toString()) ?? 0.0;
        if (grade >= 10) {
          // Assume each subject is 3 credits for simplicity
          passed += 3; 
        }
      }
    }

    if (mounted) {
      setState(() {
        _creditsPassed = passed;
        _progress = (_creditsPassed / _totalCredits).clamp(0.0, 1.0);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progreso Académico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${(_progress * 100).toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 5),
          Text(
            "Créditos Aprobados: $_creditsPassed / $_totalCredits",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
