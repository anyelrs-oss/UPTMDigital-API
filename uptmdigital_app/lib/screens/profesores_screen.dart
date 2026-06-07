import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/profesor.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/professor_form_screen.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';
import 'package:uptmdigital_app/services/supabase_service.dart';
import 'dart:convert';

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
    final api = ApiService();

    // Cargar departamentos/carreras para el filtro
    final carrerasData = await api.getCarreras();
    if (mounted) {
      setState(() {
        _departamentos = carrerasData.map((c) => c['nombre'].toString()).toList()..sort();
      });
    }

    // 1. Cargar caché (solo primera carga sin filtros)
    if (_searchQuery.isEmpty && _selectedDepartamento == null) {
      final cached = await api.storage.read(key: 'cached_profesores_list');
      if (cached != null && mounted) {
        final List data = jsonDecode(cached);
        setState(() {
          _allProfesores = data.map<Profesor>((json) => Profesor.fromJson(json)).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    }

    try {
      // Usar paginación y búsqueda en servidor
      final data = await api.getProfesores(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        departamento: _selectedDepartamento,
      );
      final list = data.map<Profesor>((json) => Profesor.fromJson(json)).toList();
      
      if (mounted) {
        setState(() {
          _allProfesores = list;
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
                            onTap: () => _showProfessorDetail(p),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                                    backgroundImage: p.profileImageUrl != null ? NetworkImage(p.profileImageUrl!) : null,
                                    child: p.profileImageUrl == null
                                      ? Text(
                                          p.nombres.isNotEmpty ? p.nombres[0].toUpperCase() : "P",
                                          style: const TextStyle(color: AppTheme.secondary),
                                        )
                                      : null,
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
                                        Row(
                                          children: [
                                            Text(
                                              "C.I: ${p.cedula}",
                                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                            ),
                                            if (p.telefono != null) ...[
                                              const SizedBox(width: 12),
                                              const Icon(Icons.phone, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(p.telefono!, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                            ],
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
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showProfessorDetail(Profesor p) {
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
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                  backgroundImage: p.profileImageUrl != null ? NetworkImage(p.profileImageUrl!) : null,
                  child: p.profileImageUrl == null ? const Icon(Icons.school, size: 50, color: AppTheme.secondary) : null,
                ),
                if (p.profileImageUrl != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.delete_forever, size: 18, color: Colors.white),
                        onPressed: () => _confirmRemoveImage(p),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text("${p.nombres} ${p.apellidos}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(p.departamento, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            _detailRow(Icons.badge, "Cédula", p.cedula),
            _detailRow(Icons.email, "Correo", p.correoInstitucional),
            _detailRow(Icons.phone, "Teléfono", p.telefono ?? "No registrado"),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfessorFormScreen(profesor: p)),
                      );
                      if (result == true) _loadProfesores();
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

  void _confirmRemoveImage(Profesor p) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Imagen de Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("¿Estás seguro de que deseas quitar la imagen de perfil de este profesor?"),
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
      final deleted = await SupabaseService.instance.deleteImage(p.profileImageUrl!);

      if (deleted) {
        // 2. Limpiar en la BD (API .NET) con auditoría
        await ApiService().storage.write(key: 'pending_delete_reason', value: "ELIMINACIÓN IMAGEN PERFIL: ${reasonCtrl.text}");
        final success = await ApiService().updateProfesor(p.idProfesor, {'profileImageUrl': null});

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Imagen removida y acción auditada"), backgroundColor: Colors.green));
          Navigator.pop(context); // Cerrar modal
          _loadProfesores();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al borrar del servidor de archivos"), backgroundColor: Colors.red));
      }
    } else if (confirm == true && reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debe proporcionar un motivo"), backgroundColor: Colors.orange));
    }
  }
}
