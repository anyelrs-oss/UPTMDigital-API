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
  double _periodProgress = 0.0;
  int _creditsPassed = 0;
  int _totalCredits = 180;
  double _promedioPonderado = 0.0;
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

    // Load grades + Daree pensum data + historial in parallel
    final results = await Future.wait([
      api.getStudentGradesMe(),
      _loadDareeCredits(api),
      _loadDareePeriodProgress(api),
      api.getDareeMiHistorial(),
    ]);

    final grades = results[0] as List<dynamic>;
    final dareeCredits = results[1] as int?;
    final periodProg = results[2] as double?;
    final historial = results[3] as Map<String, dynamic>?;

    if (mounted) {
      if (dareeCredits != null && dareeCredits > 0) {
        _totalCredits = dareeCredits;
      }
      if (periodProg != null) {
        _periodProgress = periodProg;
      }

      // Prefer Daree historial for credits/GPA (consolidated, more accurate)
      if (historial != null && historial['success'] == true) {
        final resumen = historial['resumen'] as Map<String, dynamic>?;
        if (resumen != null) {
          final creditosHist = resumen['creditosAprobados'] as int?;
          final promedio = resumen['promedioPonderado'];
          if (creditosHist != null && creditosHist > 0) {
            _creditsPassed = creditosHist;
            _progress = (_creditsPassed / _totalCredits).clamp(0.0, 1.0);
          }
          if (promedio != null) {
            _promedioPonderado = (promedio is int) ? promedio.toDouble() : (promedio as num).toDouble();
          }
        }
      } else {
        // Fallback: use local grade processing
        _processGrades(grades);
      }

      setState(() => _isLoading = false);
    }
  }

  /// Fetches total credits from Daree pensum for the student's PNF
  Future<int?> _loadDareeCredits(ApiService api) async {
    try {
      // Try to get student's specific PNF via carrera mapping
      final cachedUser = await api.storage.read(key: 'cached_user_me');
      int? pnfId;

      if (cachedUser != null) {
        final userData = jsonDecode(cachedUser);
        final carrera = userData['carrera'] as String?;
        if (carrera != null && carrera.isNotEmpty) {
          final miPnf = await api.getDareeMiPnf(carrera);
          if (miPnf != null) {
            pnfId = miPnf['id'] as int?;
          }
        }
      }

      // Fallback to first PNF if mapping failed
      if (pnfId == null) {
        final pnfs = await api.getDareePnfs();
        if (pnfs.isEmpty) return null;
        pnfId = pnfs.first['id'] as int;
      }

      final pensum = await api.getDareePensum(pnfId);
      if (pensum == null) return null;

      final data = pensum['data'] as List<dynamic>? ?? [];
      int total = 0;
      for (var uc in data) {
        total += (uc['unidadesCredito'] as int?) ?? 0;
      }
      return total > 0 ? total : null;
    } catch (e) {
      debugPrint('Daree credits error: $e');
      return null;
    }
  }

  /// Calculates period progress from Daree's periodo activo dates
  Future<double?> _loadDareePeriodProgress(ApiService api) async {
    try {
      final periodo = await api.getDareePeriodoActivo();
      if (periodo == null) return null;

      final inicio = periodo['fechaInicio'];
      final fin = periodo['fechaFin'];
      if (inicio == null || fin == null) return null;

      final startDate = DateTime.tryParse(inicio.toString());
      final endDate = DateTime.tryParse(fin.toString());
      if (startDate == null || endDate == null) return null;

      final now = DateTime.now();
      final totalDays = endDate.difference(startDate).inDays;
      if (totalDays <= 0) return null;

      final elapsedDays = now.difference(startDate).inDays;
      return (elapsedDays / totalDays).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Period progress error: $e');
      return null;
    }
  }

  void _processGrades(List<dynamic> grades) {
    int passed = 0;
    for (var nota in grades) {
      final grade = double.tryParse(nota['calificacion'].toString()) ?? 0.0;
      // Use Daree's nota_minima per UC (12 Regular, 16 Proyecto), default 12
      final notaMinima = (nota['notaMinima'] as int?) ?? 12;
      if (grade >= notaMinima) {
        // Use real credits if available from nota, else estimate 3
        final credits = nota['unidadesCredito'] as int? ?? 3;
        passed += credits;
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
            periodProgress: _periodProgress,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Carrera", "${(_progress * 100).toInt()}%", AppTheme.primary),
              _buildStatItem("Trimestre", "${(_periodProgress * 100).toInt()}%", AppTheme.secondary),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            "Créditos Aprobados: $_creditsPassed / $_totalCredits",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (_promedioPonderado > 0) ...[
            const SizedBox(height: 4),
            Text(
              "Promedio Ponderado: ${_promedioPonderado.toStringAsFixed(2)}",
              style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
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
