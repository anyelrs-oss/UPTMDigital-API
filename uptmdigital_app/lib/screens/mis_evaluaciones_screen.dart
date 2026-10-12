import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

/// Pantalla para que el ESTUDIANTE vea el plan de evaluación de sus materias inscritas.
/// Carga las inscripciones del periodo activo y muestra las evaluaciones por sección.
class MisEvaluacionesScreen extends StatefulWidget {
  const MisEvaluacionesScreen({super.key});

  @override
  State<MisEvaluacionesScreen> createState() => _MisEvaluacionesScreenState();
}

class _MisEvaluacionesScreenState extends State<MisEvaluacionesScreen> {
  List<dynamic> _inscripciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInscripciones();
  }

  Future<void> _loadInscripciones() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getDareeMisInscripciones();
    if (mounted) {
      setState(() {
        _inscripciones = (data?['data'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Plan de Evaluaciones")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inscripciones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No hay materias inscritas.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInscripciones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _inscripciones.length,
                    itemBuilder: (_, i) {
                      final insc = _inscripciones[i];
                      return _MateriaEvaluacionCard(
                        seccionId: insc['seccionId'] as String? ?? '',
                        nombreUc: insc['nombreUc'] as String? ?? 'N/A',
                        codigoUc: insc['codigoUc'] as String? ?? '',
                        docenteNombre: insc['docenteNombre'] as String? ?? 'N/A',
                      );
                    },
                  ),
                ),
    );
  }
}

/// Card por materia que carga sus evaluaciones on-demand
class _MateriaEvaluacionCard extends StatefulWidget {
  final String seccionId;
  final String nombreUc;
  final String codigoUc;
  final String docenteNombre;

  const _MateriaEvaluacionCard({
    required this.seccionId,
    required this.nombreUc,
    required this.codigoUc,
    required this.docenteNombre,
  });

  @override
  State<_MateriaEvaluacionCard> createState() => _MateriaEvaluacionCardState();
}

class _MateriaEvaluacionCardState extends State<_MateriaEvaluacionCard> {
  List<dynamic>? _evaluaciones;
  bool _isLoading = false;
  num _totalPorcentaje = 0;

  Future<void> _loadEvaluaciones() async {
    if (_evaluaciones != null) return; // already loaded
    setState(() => _isLoading = true);
    final data = await ApiService().getDareeEvaluaciones(widget.seccionId);
    if (mounted) {
      setState(() {
        _evaluaciones = (data?['data'] as List<dynamic>?) ?? [];
        _totalPorcentaje = (data?['totalPorcentaje'] as num?) ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InstitutionalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          onExpansionChanged: (expanded) {
            if (expanded) _loadEvaluaciones();
          },
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment, color: AppTheme.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.nombreUc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      "${widget.codigoUc} • ${widget.docenteNombre}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (_evaluaciones != null && _evaluaciones!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "No hay evaluaciones definidas aún.",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              )
            else if (_evaluaciones != null) ...[
              // Progress bar of total percentage
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRoundedRect(
                        child: LinearProgressIndicator(
                          value: (_totalPorcentaje / 100).clamp(0.0, 1.0).toDouble(),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _totalPorcentaje == 100 ? Colors.green : Colors.orange,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$_totalPorcentaje%",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _totalPorcentaje == 100 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              // List of evaluations
              ..._evaluaciones!.map((e) => _buildEvalItem(e)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvalItem(dynamic eval) {
    final nombre = eval['nombre'] as String? ?? 'Evaluación';
    final porcentaje = eval['porcentaje'] as num? ?? 0;
    final fechaRaw = eval['fechaEvaluacion'] as String?;
    final fecha = fechaRaw?.split('T')[0] ?? 'Sin fecha';
    final isPast = fechaRaw != null && DateTime.tryParse(fechaRaw)?.isBefore(DateTime.now()) == true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPast ? Colors.grey.shade100 : AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "${porcentaje.toInt()}%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPast ? Colors.grey : AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isPast ? Colors.grey : Colors.black87,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(fecha, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          if (isPast)
            Icon(Icons.check, size: 18, color: Colors.grey[400])
          else
            Icon(Icons.schedule, size: 18, color: Colors.orange[300]),
        ],
      ),
    );
  }
}

/// Helper widget for rounded LinearProgressIndicator
class ClipRoundedRect extends StatelessWidget {
  final Widget child;
  const ClipRoundedRect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: child,
    );
  }
}
