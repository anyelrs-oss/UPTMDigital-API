import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';
import 'package:uptmdigital_app/screens/evaluar_screen.dart';
import 'package:uptmdigital_app/screens/asistencias_screen.dart';
import 'package:uptmdigital_app/screens/estudiantes_screen.dart';
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
    final api = ApiService();

    try {
      final data = await api.getAsignaturas();
      var list = data.map<Asignatura>((json) => Asignatura.fromJson(json)).toList();

      if (widget.professorId != null) {
        list = list.where((a) => a.profesorId == widget.professorId).toList();
      }

      final deptSet = <String>{};
      for (var a in list) {
        if (a.departamento.isNotEmpty) deptSet.add(a.departamento);
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
                ? const Center(child: Text("No hay asignaturas registradas"))
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
    );
  }

  Widget _buildAsignaturaCard(Asignatura a) {
    final bool isAdmin = widget.professorId == null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
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
                      Text(a.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        "Cod: ${a.codigo} • Sem: ${a.semestreNombre}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  icon: Icons.people_outline,
                  label: "Alumnos",
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EstudiantesScreen())),
                ),
                _buildQuickAction(
                  icon: Icons.chat_bubble_outline,
                  label: "Chat",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        asignaturaId: a.idAsignatura,
                        title: a.nombre,
                        userName: "Administrador",
                      ),
                    ));
                  },
                ),
                _buildQuickAction(
                  icon: Icons.check_circle_outline,
                  label: "Asistencias",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AsistenciasScreen(
                        asignaturaId: a.idAsignatura,
                        asignaturaNombre: a.nombre,
                      ),
                    ));
                  },
                ),
                if (!isAdmin) // Acciones extra si es profesor
                  _buildQuickAction(
                    icon: Icons.assignment_outlined,
                    label: "Evaluar",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EvaluarScreen(
                          asignaturaId: a.idAsignatura,
                          asignaturaNombre: a.nombre,
                        ),
                      ));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
