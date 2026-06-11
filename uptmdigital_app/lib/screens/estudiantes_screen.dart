import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/estudiante.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/student_form_screen.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';
import 'package:uptmdigital_app/services/supabase_service.dart';
import 'dart:convert';

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
    final api = ApiService();

    // Cargar lista de carreras para los filtros primero
    final carrerasData = await api.getCarreras();
    if (mounted) {
      setState(() {
        _carreras = carrerasData.map((c) => c['nombre'].toString()).toList()..sort();
      });
    }

    // 1. Cargar caché (solo para la primera página y sin filtros)
    if (_searchQuery.isEmpty && _selectedCarrera == null) {
      final cached = await api.storage.read(key: 'cached_estudiantes_list');
      if (cached != null && mounted) {
        final List data = jsonDecode(cached);
        setState(() {
          _allEstudiantes = data.map<Estudiante>((json) => Estudiante.fromJson(json)).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    }

    try {
      final data = await api.getEstudiantes(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        carrera: _selectedCarrera,
      );
      final list = data.map<Estudiante>((json) => Estudiante.fromJson(json)).toList();
      
      if (mounted) {
        setState(() {
          _allEstudiantes = list;
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
    );
  }

  Widget _buildStudentCard(Estudiante e) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showStudentDetail(e),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: (e.profileImageUrl != null && e.profileImageUrl!.isNotEmpty) ? NetworkImage(e.profileImageUrl!) : null,
                child: (e.profileImageUrl == null || e.profileImageUrl!.isEmpty)
                  ? Text(
                      e.nombres.isNotEmpty ? e.nombres[0].toUpperCase() : "?",
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
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
                        if (e.telefono != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(e.telefono!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetail(Estudiante e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  backgroundImage: (e.profileImageUrl != null && e.profileImageUrl!.isNotEmpty) ? NetworkImage(e.profileImageUrl!) : null,
                  child: (e.profileImageUrl == null || e.profileImageUrl!.isEmpty) ? const Icon(Icons.person, size: 50, color: AppTheme.primary) : null,
                ),
                if (e.profileImageUrl != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.delete_forever, size: 18, color: Colors.white),
                        onPressed: () => _confirmRemoveImage(e),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text("${e.nombres} ${e.apellidos}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(e.carreraNombre, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            _detailRow(Icons.badge, "Cédula", e.cedula),
            _detailRow(Icons.email, "Correo", e.correoInstitucional),
            _detailRow(Icons.phone, "Teléfono", e.telefono ?? "No registrado"),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StudentFormScreen(estudiante: e)),
                      );
                      if (result == true) _loadEstudiantes();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("EDITAR PERFIL"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  void _confirmRemoveImage(Estudiante e) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Imagen de Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("¿Estás seguro de que deseas quitar la imagen de perfil de este estudiante?"),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: "Motivo",
                hintText: "Ej: Imagen inapropiada...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("REMOVER"),
          ),
        ],
      ),
    );

    if (confirm == true && reasonCtrl.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Procesando eliminación...")));

      // 1. Borrar del Storage (Supabase)
      final deleted = await SupabaseService.instance.deleteImage(e.profileImageUrl!);

      if (deleted) {
        // 2. Limpiar en la BD (API .NET) con auditoría
        await ApiService().storage.write(key: 'pending_delete_reason', value: "ELIMINACIÓN IMAGEN PERFIL: ${reasonCtrl.text}");
        final success = await ApiService().updateStudent(e.idEstudiante, {'profileImageUrl': null});

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Imagen removida y acción auditada"), backgroundColor: Colors.green));
          Navigator.pop(context); // Cerrar modal
          _loadEstudiantes();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al borrar del servidor de archivos"), backgroundColor: Colors.red));
      }
    } else if (confirm == true && reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debe proporcionar un motivo"), backgroundColor: Colors.orange));
    }
  }
}