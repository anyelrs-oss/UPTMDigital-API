import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

/// Pantalla para que el ESTUDIANTE vea su asistencia desde Daree.
/// Dos vistas: Resumen por materia → Detalle por fecha al tocar.
class MiAsistenciaScreen extends StatefulWidget {
  const MiAsistenciaScreen({super.key});

  @override
  State<MiAsistenciaScreen> createState() => _MiAsistenciaScreenState();
}

class _MiAsistenciaScreenState extends State<MiAsistenciaScreen> {
  List<dynamic> _resumen = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResumen();
  }

  Future<void> _loadResumen() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getDareeMisAsistencias();
    if (mounted) {
      setState(() {
        _resumen = (data?['data'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Asistencia")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resumen.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadResumen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resumen.length,
                    itemBuilder: (_, i) => _buildMateriaCard(_resumen[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No hay registros de asistencia.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMateriaCard(dynamic materia) {
    final nombre = materia['nombreUc'] as String? ?? 'N/A';
    final codigo = materia['codigoUc'] as String? ?? '';
    final porcentaje = (materia['porcentajeAsistencia'] as num?)?.toDouble() ?? 0;
    final total = materia['totalClases'] as int? ?? 0;
    final presentes = materia['presentes'] as int? ?? 0;
    final ausentes = materia['ausentes'] as int? ?? 0;
    final justificadas = materia['justificadas'] as int? ?? 0;
    final tardanzas = materia['tardanzas'] as int? ?? 0;
    final seccionId = materia['seccionId'] as String? ?? '';

    // Color por umbral 75%
    final Color statusColor;
    final IconData statusIcon;
    if (porcentaje >= 90) {
      statusColor = Colors.green.shade600;
      statusIcon = Icons.check_circle;
    } else if (porcentaje >= 75) {
      statusColor = Colors.orange.shade600;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.red.shade600;
      statusIcon = Icons.error;
    }

    return InstitutionalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetalle(seccionId, nombre),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: materia + porcentaje
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${porcentaje.toInt()}%",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(codigo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip("Total", "$total", Colors.blueGrey),
                _statChip("Presente", "$presentes", Colors.green),
                _statChip("Ausente", "$ausentes", Colors.red),
                _statChip("Justif.", "$justificadas", Colors.orange),
                _statChip("Tardanza", "$tardanzas", Colors.amber.shade700),
              ],
            ),
            // Warning if below 75%
            if (porcentaje < 75 && total > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 6),
                    Text(
                      "Riesgo: asistencia por debajo del 75% mínimo",
                      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  // ─── Detalle por fecha ────────────────────────────────────

  void _showDetalle(String seccionId, String nombreUc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AsistenciaDetalleScreen(seccionId: seccionId, nombreUc: nombreUc),
      ),
    );
  }
}

/// Detalle de asistencia para una materia específica
class _AsistenciaDetalleScreen extends StatefulWidget {
  final String seccionId;
  final String nombreUc;

  const _AsistenciaDetalleScreen({required this.seccionId, required this.nombreUc});

  @override
  State<_AsistenciaDetalleScreen> createState() => _AsistenciaDetalleScreenState();
}

class _AsistenciaDetalleScreenState extends State<_AsistenciaDetalleScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getDareeMisAsistencias(seccionId: widget.seccionId);
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _data?['resumen'] as Map<String, dynamic>?;
    final registros = (_data?['data'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.nombreUc)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary header
                if (resumen != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem("Clases", "${resumen['totalClases'] ?? 0}"),
                        _summaryItem("Presentes", "${resumen['presentes'] ?? 0}"),
                        _summaryItem("Ausentes", "${resumen['ausentes'] ?? 0}"),
                        _summaryItem("Asistencia", "${resumen['porcentajeAsistencia'] ?? 0}%"),
                      ],
                    ),
                  ),
                // List of records
                Expanded(
                  child: registros.isEmpty
                      ? const Center(child: Text("Sin registros detallados"))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: registros.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) => _buildRegistro(registros[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRegistro(dynamic reg) {
    final fecha = reg['fecha']?.toString().split('T')[0] ?? 'N/A';
    final estado = reg['estado'] as String? ?? 'N/A';
    final obs = reg['observacion'] as String?;

    Color color;
    IconData icon;
    switch (estado) {
      case 'PRESENTE':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'AUSENTE':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'JUSTIFICADO':
        color = Colors.orange;
        icon = Icons.info;
        break;
      case 'TARDANZA':
        color = Colors.amber.shade700;
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(fecha, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: obs != null && obs.isNotEmpty ? Text(obs, style: const TextStyle(fontSize: 12)) : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          estado,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
