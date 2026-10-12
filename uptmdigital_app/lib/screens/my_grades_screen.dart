import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class MyGradesScreen extends StatefulWidget {
  const MyGradesScreen({super.key});

  @override
  State<MyGradesScreen> createState() => _MyGradesScreenState();
}

class _MyGradesScreenState extends State<MyGradesScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _grades = [];
  Map<String, dynamic>? _historial;
  bool _isLoadingGrades = true;
  bool _isLoadingHistorial = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGrades();
    _loadHistorial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoadingGrades = true);
    final data = await ApiService().getStudentGradesMe();
    if (mounted) {
      setState(() {
        _grades = data;
        _isLoadingGrades = false;
      });
    }
  }

  Future<void> _loadHistorial() async {
    setState(() => _isLoadingHistorial = true);
    final data = await ApiService().getDareeMiHistorial();
    if (mounted) {
      setState(() {
        _historial = data;
        _isLoadingHistorial = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: "Periodo Actual", icon: Icon(Icons.assignment, size: 18)),
              Tab(text: "Historial", icon: Icon(Icons.history, size: 18)),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentPeriodTab(),
              _buildHistorialTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Tab 1: Periodo Actual ─────────────────────────────────

  Widget _buildCurrentPeriodTab() {
    if (_isLoadingGrades) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_grades.isEmpty) {
      return _buildEmptyState("Aún no tienes notas registradas\nen este periodo.");
    }
    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grades.length,
        itemBuilder: (context, index) => _buildGradeCard(_grades[index]),
      ),
    );
  }

  // ─── Tab 2: Historial Académico ────────────────────────────

  Widget _buildHistorialTab() {
    if (_isLoadingHistorial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historial == null || _historial!['success'] != true) {
      return _buildEmptyState("No se pudo cargar el historial académico.");
    }

    final resumen = _historial!['resumen'] as Map<String, dynamic>? ?? {};
    final porTrayecto = _historial!['porTrayecto'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadHistorial,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          _buildResumenCard(resumen),
          const SizedBox(height: 8),
          // Per-trayecto sections
          ...porTrayecto.map((t) => _buildTrayectoSection(t)),
        ],
      ),
    );
  }

  Widget _buildResumenCard(Map<String, dynamic> resumen) {
    final promedio = (resumen['promedioPonderado'] as num?)?.toDouble() ?? 0;
    final aprobadas = resumen['aprobadas'] ?? 0;
    final reprobadas = resumen['reprobadas'] ?? 0;
    final creditos = resumen['creditosAprobados'] ?? 0;
    final total = resumen['totalMaterias'] ?? 0;

    return InstitutionalCard(
      child: Column(
        children: [
          // Promedio prominente
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                promedio.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text("Promedio Ponderado", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip("Total", "$total", Colors.blueGrey),
              _buildStatChip("Aprobadas", "$aprobadas", Colors.green),
              _buildStatChip("Reprobadas", "$reprobadas", Colors.red),
              _buildStatChip("Créditos", "$creditos", AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTrayectoSection(dynamic trayecto) {
    final nombre = trayecto['trayecto'] as String? ?? "Sin Trayecto";
    final materias = trayecto['materias'] as List<dynamic>? ?? [];
    final creditos = trayecto['creditosTrayecto'] as int? ?? 0;

    return InstitutionalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(
                child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$creditos UC",
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          children: materias.map((m) => _buildHistorialItem(m)).toList(),
        ),
      ),
    );
  }

  Widget _buildHistorialItem(dynamic materia) {
    final nota = (materia['notaFinal'] as num?)?.toDouble();
    final condicion = materia['condicion'] as String? ?? '';
    final nombre = materia['nombreUc'] as String? ?? 'N/A';
    final codigo = materia['codigoUc'] as String? ?? '';
    final creditos = materia['unidadesCredito'] as int? ?? 0;
    final periodo = materia['periodo'] as String? ?? '';

    Color color;
    IconData icon;
    switch (condicion) {
      case 'APROBADO':
        color = Colors.green.shade600;
        icon = Icons.check_circle;
        break;
      case 'REPROBADO':
        color = Colors.red.shade600;
        icon = Icons.cancel;
        break;
      case 'EQUIVALENCIA':
        color = Colors.blue.shade600;
        icon = Icons.swap_horiz;
        break;
      case 'RETIRO':
        color = Colors.orange.shade600;
        icon = Icons.remove_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Nota circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: nota != null
                  ? Text(
                      nota.toInt().toString(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Row(
                  children: [
                    Text(codigo, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text("${creditos}UC", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    if (periodo.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(periodo, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Text(
                  condicion,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(dynamic grade) {
    double calificacion = (grade['calificacion'] as num).toDouble();
    // Use Daree's nota_minima per UC (12 Regular, 16 Proyecto), default 12
    int notaMinima = (grade['notaMinima'] as int?) ?? 12;

    // Lógica de "Semáforo" con umbrales reales de Daree
    Color colorEstado;
    String textoEstado;
    IconData iconoEstado;

    if (calificacion >= 18) {
      colorEstado = Colors.amber.shade700;
      textoEstado = "EXCELENTE";
      iconoEstado = Icons.stars;
    } else if (calificacion >= notaMinima) {
      colorEstado = Colors.green.shade600;
      textoEstado = "APROBADO";
      iconoEstado = Icons.check_circle_outline;
    } else {
      colorEstado = Colors.red.shade600;
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
                    fontWeight: FontWeight.w900,
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
