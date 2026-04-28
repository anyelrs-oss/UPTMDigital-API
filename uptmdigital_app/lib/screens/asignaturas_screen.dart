import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/asignatura_form_screen.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';
import 'package:uptmdigital_app/services/pdf_service.dart';
import 'package:uptmdigital_app/services/excel_service.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';

class AsignaturasScreen extends StatefulWidget {
  final int? professorId;
  const AsignaturasScreen({super.key, this.professorId});

  @override
  State<AsignaturasScreen> createState() => _AsignaturasScreenState();
}

class _AsignaturasScreenState extends State<AsignaturasScreen> {
  List<Asignatura> _allAsignaturas = [];
  List<Asignatura> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDepartamento;
  List<String> _departamentos = [];

  @override
  void initState() {
    super.initState();
    _loadAsignaturas();
  }

  Future<void> _loadAsignaturas() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getAsignaturas();
      var list = data.map<Asignatura>((json) => Asignatura.fromJson(json)).toList();
      if (widget.professorId != null) {
        list = list.where((a) => a.profesorId == widget.professorId).toList();
      }

      final deptSet = <String>{};
      for (var a in list) {
        if (a.departamento != null && a.departamento!.isNotEmpty) deptSet.add(a.departamento!);
      }

      if (mounted) {
        setState(() {
          _allAsignaturas = list;
          _departamentos = deptSet.toList()..sort();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var result = _allAsignaturas;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((a) =>
        a.nombre.toLowerCase().contains(q) ||
        a.codigo.toLowerCase().contains(q)
      ).toList();
    }

    if (_selectedDepartamento != null) {
      result = result.where((a) => a.departamento == _selectedDepartamento).toList();
    }

    _filtered = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Asignaturas (${_filtered.length})"),
      ),
      body: Column(
        children: [
          SearchFilterBar(
            hintText: "Buscar por nombre o código...",
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            filters: [
              FilterChipData(
                label: "Todas",
                isSelected: _selectedDepartamento == null,
                onSelected: (_) => setState(() {
                  _selectedDepartamento = null;
                  _applyFilters();
                }),
              ),
              ..._departamentos.map((d) => FilterChipData(
                label: d,
                isSelected: _selectedDepartamento == d,
                onSelected: (_) => setState(() {
                  _selectedDepartamento = _selectedDepartamento == d ? null : d;
                  _applyFilters();
                }),
              )),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? "Sin resultados" : "No hay asignaturas registradas",
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAsignaturas,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildAsignaturaCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.professorId == null ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AsignaturaFormScreen()),
          );
          if (result == true) _loadAsignaturas();
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildAsignaturaCard(Asignatura a) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AsignaturaFormScreen(asignatura: a)),
          );
          if (result == true) _loadAsignaturas();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple.withOpacity(0.1),
                child: Text(
                  a.nombre.isNotEmpty ? a.nombre[0].toUpperCase() : "A",
                  style: const TextStyle(color: Colors.purple),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(a.codigo, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Sem: ${a.semestreNombre} • UC: ${a.creditos}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.blue),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      asignaturaId: a.idAsignatura,
                      asignaturaNombre: a.nombre,
                      userName: "Profesor",
                    ),
                  ));
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.download_for_offline, color: Colors.green),
                onSelected: (value) async {
                  final students = await ApiService().getInscripcionesByAsignatura(a.idAsignatura);
                  if (students.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay estudiantes inscritos.")));
                    }
                    return;
                  }
                  if (value == 'pdf') {
                    await PdfService().generateClassListPdf(a.nombre, students);
                  } else if (value == 'excel') {
                    await ExcelService().generateClassListExcel(a.nombre, students);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('Lista en PDF')])),
                  const PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 8), Text('Lista en Excel')])),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(a),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Asignatura a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Desactivar Asignatura"),
        content: Text("¿Desactivar ${a.nombre}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Desactivar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService().deleteAsignatura(a.idAsignatura);
      if (success) _loadAsignaturas();
    }
  }
}
