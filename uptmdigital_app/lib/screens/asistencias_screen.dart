import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';

import 'package:uptmdigital_app/utils/export_helper.dart';

class AsistenciasScreen extends StatefulWidget {
  final int? professorId;
  const AsistenciasScreen({super.key, this.professorId});

  @override
  State<AsistenciasScreen> createState() => _AsistenciasScreenState();
}

class _AsistenciasScreenState extends State<AsistenciasScreen> {
  List<dynamic> _asistencias = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAsistencias();
  }

  Future<void> _loadAsistencias() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getAsistencias();
    if (mounted) {
      setState(() {
        _asistencias = data;
        _isLoading = false;
      });
    }
  }

  void _exportarExcel() async {
    final headers = ["Estudiante", "Cédula", "Asignatura", "Fecha", "Estado"];
    final rows = _asistencias.map((a) {
      final student = a['estudiante'] != null ? "${a['estudiante']['nombres']} ${a['estudiante']['apellidos']}" : "N/A";
      final cedula = a['estudiante'] != null ? a['estudiante']['cedula'] : "N/A";
      final subject = a['asignatura'] != null ? a['asignatura']['nombre'] : "N/A";
      final date = a['fecha'].split('T')[0];
      return [student, cedula, subject, date, a['estado']];
    }).toList();

    await ExportHelper.exportToExcel(fileName: "Reporte_Asistencias", headers: headers, rows: rows);
  }

  void _exportarPDF() async {
    final headers = ["Estudiante", "Cédula", "Fecha", "Estado"];
    final data = _asistencias.map((a) {
      final student = a['estudiante'] != null ? "${a['estudiante']['nombres']} ${a['estudiante']['apellidos']}" : "N/A";
      final cedula = a['estudiante'] != null ? a['estudiante']['cedula'] : "N/A";
      final date = a['fecha'].split('T')[0];
      return [student, cedula, date, a['estado'].toString()];
    }).toList();

    await ExportHelper.exportToPDF(
      title: "Control de Asistencia Estudiantil",
      headers: headers,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.professorId == null;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Asistencia"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (val) {
               if (val == 'pdf') _exportarPDF();
               if (val == 'excel') _exportarExcel();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'pdf', child: Text("Exportar PDF")),
              const PopupMenuItem(value: 'excel', child: Text("Exportar Excel")),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          SearchFilterBar(
            hintText: "Buscar por cédula o nombre...",
            onSearchChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _asistencias.isEmpty
                ? const Center(child: Text("Sin registros"))
                : RefreshIndicator(
                    onRefresh: _loadAsistencias,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _asistencias.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) => _buildAsistenciaItem(_asistencias[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsistenciaItem(dynamic a) {
    final date = a['fecha'].split('T')[0];
    final String student = a['estudiante'] != null ? "${a['estudiante']['nombres']} ${a['estudiante']['apellidos']}" : "ID: ${a['estudianteId']}";
    final String subject = a['asignatura'] != null ? a['asignatura']['nombre'] : "Materia: ${a['asignaturaId']}";

    if (_searchQuery.isNotEmpty && !student.toLowerCase().contains(_searchQuery)) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        child: const Icon(Icons.check, color: Colors.green),
      ),
      title: Text(student, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text("$subject • $date", style: const TextStyle(fontSize: 12)),
      trailing: Text(a['estado'], style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
