import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/profesor.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/professor_form_screen.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  List<Profesor> _allProfesores = [];
  List<Profesor> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDepartamento;
  List<String> _departamentos = [];

  @override
  void initState() {
    super.initState();
    _loadProfesores();
  }

  Future<void> _loadProfesores() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getProfesores();
      final list = data.map<Profesor>((json) => Profesor.fromJson(json)).toList();
      
      final deptSet = <String>{};
      for (var p in list) {
        if (p.departamento.isNotEmpty) deptSet.add(p.departamento);
      }

      if (mounted) {
        setState(() {
          _allProfesores = list;
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
    var result = _allProfesores;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
        p.nombres.toLowerCase().contains(q) ||
        p.apellidos.toLowerCase().contains(q) ||
        p.cedula.toLowerCase().contains(q)
      ).toList();
    }

    if (_selectedDepartamento != null) {
      result = result.where((p) => p.departamento == _selectedDepartamento).toList();
    }

    _filtered = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profesores (${_filtered.length})"),
      ),
      body: Column(
        children: [
          SearchFilterBar(
            hintText: "Buscar por nombre o cédula...",
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            filters: [
              FilterChipData(
                label: "Todos",
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
                        Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? "Sin resultados" : "No hay profesores registrados",
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProfesores,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        return Card(
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProfessorFormScreen(profesor: p)),
                              );
                              if (result == true) _loadProfesores();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.secondary.withOpacity(0.1),
                                    child: Text(
                                      p.nombres.isNotEmpty ? p.nombres[0].toUpperCase() : "P",
                                      style: const TextStyle(color: AppTheme.secondary),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${p.nombres} ${p.apellidos}",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          p.departamento,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                        Text(
                                          "C.I: ${p.cedula}",
                                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _confirmDelete(p),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfessorFormScreen()),
          );
          if (result == true) _loadProfesores();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(Profesor p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Desactivar Profesor"),
        content: Text("¿Desactivar a ${p.nombres} ${p.apellidos}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Desactivar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService().deleteProfesor(p.idProfesor);
      if (success) _loadProfesores();
    }
  }
}
