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
  List<dynamic> _notas = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotas();
  }

  Future<void> _loadNotas() async {
    setState(() => _isLoading = true);
    
    final data = await ApiService().getNotas(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      asignaturaId: widget.asignaturaId,
      estudianteId: widget.estudianteId,
    );
    if (mounted) {
      setState(() {
        _notas = data;
        _isLoading = false;
      });
    }
  }

  void _exportarActaPDF() async {
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

  @override
  Widget build(BuildContext context) {
    final String title = widget.estudianteNombre != null
        ? "Notas de ${widget.estudianteNombre}"
        : (widget.asignaturaNombre ?? "Control de Calificaciones");

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_notas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportarActaPDF,
              tooltip: "Generar Acta PDF",
            )
        ],
      ),
      body: Column(
        children: [
          if (widget.asignaturaId == null) // Solo mostrar búsqueda si no es jerárquico
            SearchFilterBar(
              hintText: "Buscar por cédula o nombre...",
              onSearchChanged: (val) {
                _searchQuery = val;
                _loadNotas();
              },
            ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notas.isEmpty
                ? const Center(child: Text("No se encontraron registros."))
                : RefreshIndicator(
                    onRefresh: _loadNotas,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildNotaCard(_notas[i]),
                    ),
                  ),
          ),
        ],
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
}
