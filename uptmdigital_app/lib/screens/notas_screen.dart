import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';
import 'package:intl/intl.dart';
import 'package:uptmdigital_app/utils/export_helper.dart';

class NotasScreen extends StatefulWidget {
  final int? professorId;
  final int? asignaturaId;
  final String? asignaturaNombre;
  final int? estudianteId;
  final String? estudianteNombre;

  const NotasScreen({
    super.key, 
    this.professorId, 
    this.asignaturaId, 
    this.asignaturaNombre,
    this.estudianteId,
    this.estudianteNombre,
  });

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  // Estado para reporte normal
  List<dynamic> _notas = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Estado para consolidado
  bool _isConsolidado = false;
  List<dynamic> _evaluaciones = [];
  List<dynamic> _estudiantesConsolidado = [];
  bool _subidaNotasHabilitada = false;
  bool _notasConfirmadas = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _isConsolidado = widget.asignaturaId != null;
    _loadNotas();
  }

  Future<void> _loadNotas() async {
    setState(() => _isLoading = true);
    final api = ApiService();

    try {
      if (_isConsolidado) {
        // Cargar reporte consolidado
        final data = await api.getNotasConsolidado(widget.asignaturaId!);
        final habilitarSetting = await api.getGlobalSetting("HabilitarSubidaNotas");
        final confirmadoSetting = await api.getGlobalSetting("Confirmado_Asignatura_${widget.asignaturaId}");

        if (data != null && mounted) {
          setState(() {
            _evaluaciones = data['evaluaciones'] ?? [];
            _estudiantesConsolidado = data['estudiantes'] ?? [];
            _subidaNotasHabilitada = habilitarSetting == "true";
            _notasConfirmadas = confirmadoSetting == "true";
          });
        }
      } else {
        // Cargar reporte individual estándar
        final data = await api.getNotas(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          asignaturaId: widget.asignaturaId,
          estudianteId: widget.estudianteId,
        );
        if (mounted) {
          setState(() {
            _notas = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading grades: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _exportarActaPDF() async {
    if (_isConsolidado) {
      final headers = ["Estudiante", "Cédula", ..._evaluaciones.map((e) => "${e['nombre']} (${e['ponderacion']}%)"), "Nota Final"];
      final data = _estudiantesConsolidado.map<List<String>>((est) {
        final califs = est['calificaciones'] as Map<String, dynamic>? ?? {};
        return [
          "${est['nombres']} ${est['apellidos']}",
          est['cedula']?.toString() ?? "N/A",
          ..._evaluaciones.map((e) {
            final nota = califs[e['idEvaluacion'].toString()];
            return nota != null ? "$nota pts" : "-";
          }),
          "${est['notaFinal']} pts",
        ];
      }).toList();

      await ExportHelper.exportToPDF(
        title: "ACTA CONSOLIDADA DE CALIFICACIONES",
        subtitle: widget.asignaturaNombre ?? "Materia",
        headers: headers,
        data: data,
      );
    } else {
      final headers = ["Estudiante", "Cédula", "Calificación"];
      final data = _notas.map((n) {
        return [
          n['estudianteNombre']?.toString() ?? "N/A",
          n['estudianteCedula']?.toString() ?? "N/A",
          "${n['calificacion']} pts",
        ];
      }).toList();

      await ExportHelper.exportToPDF(
        title: "ACTA DE CALIFICACIONES",
        subtitle: widget.asignaturaNombre ?? "Materia General",
        headers: headers,
        data: data,
      );
    }
  }

  void _exportarActaExcel() async {
    if (!_isConsolidado) return;

    final headers = ["Estudiante", "Cédula", ..._evaluaciones.map((e) => "${e['nombre']} (${e['ponderacion']}%)"), "Nota Final"];
    final rows = _estudiantesConsolidado.map<List<dynamic>>((est) {
      final califs = est['calificaciones'] as Map<String, dynamic>? ?? {};
      return [
        "${est['nombres']} ${est['apellidos']}",
        est['cedula']?.toString() ?? "N/A",
        ..._evaluaciones.map((e) => califs[e['idEvaluacion'].toString()] ?? "-"),
        est['notaFinal'] ?? 0.0,
      ];
    }).toList();

    await ExportHelper.exportToExcel(
      fileName: "acta_notas_${widget.asignaturaId}",
      headers: headers,
      rows: rows,
    );
  }

  Future<void> _confirmarCargaNotas() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Carga de Notas"),
        content: const Text(
          "¿Está seguro de que desea confirmar las calificaciones de esta asignatura?\n\n"
          "Esta acción es definitiva y guardará la carga final del semestre. "
          "No podrá realizar más modificaciones después de esto.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionLoading = true);
      final success = await ApiService().setGlobalSetting(
        "Confirmado_Asignatura_${widget.asignaturaId}",
        "true",
      );
      setState(() => _isActionLoading = false);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Calificaciones confirmadas de manera definitiva.")),
          );
        }
        _loadNotas();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al confirmar calificaciones. Verifique sus permisos."), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.estudianteNombre != null
        ? "Notas de ${widget.estudianteNombre}"
        : (widget.asignaturaNombre ?? "Control de Calificaciones");

    final bool showExportButtons = _isConsolidado
        ? _estudiantesConsolidado.isNotEmpty
        : _notas.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (showExportButtons) ...[
            if (_isConsolidado)
              IconButton(
                icon: const Icon(Icons.table_view_outlined),
                onPressed: _exportarActaExcel,
                tooltip: "Exportar Excel",
              ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportarActaPDF,
              tooltip: "Generar Acta PDF",
            )
          ]
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isConsolidado) _buildHeaderBanner(),
                if (!_isConsolidado && widget.asignaturaId == null)
                  SearchFilterBar(
                    hintText: "Buscar por cédula o nombre...",
                    onSearchChanged: (val) {
                      _searchQuery = val;
                      _loadNotas();
                    },
                  ),
                Expanded(
                  child: _isConsolidado
                      ? _buildConsolidatedView()
                      : _buildStandardView(),
                ),
                if (_isConsolidado && _subidaNotasHabilitada && !_notasConfirmadas)
                  _buildFooterAction(),
              ],
            ),
    );
  }

  Widget _buildHeaderBanner() {
    if (_notasConfirmadas) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(bottom: BorderSide(color: Colors.green.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Carga de notas firmada definitivamente. Calificaciones bloqueadas para edición.",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_subidaNotasHabilitada) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Semana de subida de notas activa. Revise las calificaciones de sus alumnos y confirme la carga final al pie de la pantalla.",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Icon(Icons.lock_clock, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Fuera de la semana de subida de notas. La confirmación definitiva no está activa en este momento.",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolidatedView() {
    if (_estudiantesConsolidado.isEmpty) {
      return const Center(child: Text("No hay estudiantes inscritos en esta materia."));
    }

    return RefreshIndicator(
      onRefresh: _loadNotas,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.primary.withValues(alpha: 0.03)),
                  columns: [
                    const DataColumn(label: Text("Estudiante", style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text("Cédula", style: TextStyle(fontWeight: FontWeight.bold))),
                    ..._evaluaciones.map((e) => DataColumn(
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "${e['nombre']}\n(${e['ponderacion']}%)",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    )),
                    const DataColumn(label: Text("Nota Final", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _estudiantesConsolidado.map((est) {
                    final califs = est['calificaciones'] as Map<String, dynamic>? ?? {};
                    return DataRow(
                      cells: [
                        DataCell(Text("${est['nombres']} ${est['apellidos']}", style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(est['cedula'] ?? 'N/A')),
                        ..._evaluaciones.map((e) {
                          final nota = califs[e['idEvaluacion'].toString()];
                          return DataCell(
                            Center(
                              child: Text(
                                nota != null ? "$nota pts" : "-",
                                style: TextStyle(
                                  fontWeight: nota != null ? FontWeight.w500 : FontWeight.normal,
                                  color: nota != null ? Colors.black87 : Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (est['notaFinal'] ?? 0) >= 9.5
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${est['notaFinal'] ?? 0} pts",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (est['notaFinal'] ?? 0) >= 9.5 ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardView() {
    if (_notas.isEmpty) {
      return const Center(child: Text("No se encontraron registros."));
    }

    return RefreshIndicator(
      onRefresh: _loadNotas,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildNotaCard(_notas[i]),
      ),
    );
  }

  Widget _buildNotaCard(dynamic n) {
    final date = DateTime.parse(n['fecha']);
    final audit = n['audit'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    n['estudianteNombre'] ?? "Estudiante",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    "${n['calificacion']} pts",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("C.I: ${n['estudianteCedula']} • ${n['asignaturaNombre']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.history, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Subida: ${DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Spacer(),
                if (audit != null) ...[
                  const Icon(Icons.lan_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("IP: ${audit['ip']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isActionLoading ? null : _confirmarCargaNotas,
          icon: _isActionLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: const Text("CONFIRMAR CARGA DE NOTAS", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
