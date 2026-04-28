import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/estudiante.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/student_form_screen.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';

class EstudiantesScreen extends StatefulWidget {
  const EstudiantesScreen({super.key});
  @override
  State<EstudiantesScreen> createState() => _EstudiantesScreenState();
}

class _EstudiantesScreenState extends State<EstudiantesScreen> {
  List<Estudiante> _allEstudiantes = [];
  List<Estudiante> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCarrera;
  List<String> _carreras = [];

  @override
  void initState() {
    super.initState();
    _loadEstudiantes();
  }

  Future<void> _loadEstudiantes() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getEstudiantes();
      final list = data.map<Estudiante>((json) => Estudiante.fromJson(json)).toList();
      
      // Extract unique carreras for filter chips
      final carreraSet = <String>{};
      for (var e in list) {
        if (e.carreraNombre.isNotEmpty) carreraSet.add(e.carreraNombre);
      }

      if (mounted) {
        setState(() {
          _allEstudiantes = list;
          _carreras = carreraSet.toList()..sort();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var result = _allEstudiantes;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) =>
        e.nombres.toLowerCase().contains(q) ||
        e.apellidos.toLowerCase().contains(q) ||
        e.cedula.toLowerCase().contains(q)
      ).toList();
    }

    if (_selectedCarrera != null) {
      result = result.where((e) => e.carreraNombre == _selectedCarrera).toList();
    }

    _filtered = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Estudiantes (${_filtered.length})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
              // "Todas" chip
              FilterChipData(
                label: "Todas",
                isSelected: _selectedCarrera == null,
                onSelected: (_) => setState(() {
                  _selectedCarrera = null;
                  _applyFilters();
                }),
              ),
              // Dynamic carrera chips
              ..._carreras.map((c) => FilterChipData(
                label: c,
                isSelected: _selectedCarrera == c,
                onSelected: (_) => setState(() {
                  _selectedCarrera = _selectedCarrera == c ? null : c;
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
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? "Sin resultados para \"$_searchQuery\"" : "No hay estudiantes registrados",
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadEstudiantes,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final e = _filtered[i];
                        return _buildStudentCard(e);
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
            MaterialPageRoute(builder: (_) => const StudentFormScreen()),
          );
          if (result == true) _loadEstudiantes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStudentCard(Estudiante e) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentFormScreen(estudiante: e)),
          );
          if (result == true) _loadEstudiantes();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  e.nombres.isNotEmpty ? e.nombres[0].toUpperCase() : "?",
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${e.nombres} ${e.apellidos}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(e.cedula, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.carreraNombre,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(e),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Estudiante e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Desactivar Estudiante"),
        content: Text("¿Desactivar a ${e.nombres} ${e.apellidos}? No se eliminará de la base de datos."),
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
      final success = await ApiService().deleteStudent(e.idEstudiante);
      if (success) {
        _loadEstudiantes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Estudiante desactivado")),
          );
        }
      }
    }
  }
}
