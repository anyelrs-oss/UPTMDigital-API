import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  List<dynamic> _allPersonal = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedRol;

  final _roles = ['Secretaria', 'Coordinador', 'Seguridad'];

  @override
  void initState() {
    super.initState();
    _loadPersonal();
  }

  Future<void> _loadPersonal() async {
    setState(() => _isLoading = true);
    // Nota: Por ahora usamos getUsuarios filtrado por estos roles
    // ya que el personal administrativo se gestiona principalmente como usuarios con roles específicos.
    final data = await ApiService().getUsuarios(limit: 100);

    if (mounted) {
      setState(() {
        _allPersonal = data.where((u) => _roles.contains(u['rol'])).toList();
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var result = _allPersonal;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((u) =>
        (u['nombreUsuario'] ?? '').toString().toLowerCase().contains(q) ||
        (u['cedula'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }

    if (_selectedRol != null) {
      result = result.where((u) => u['rol'] == _selectedRol).toList();
    }

    _filtered = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Personal Administrativo (${_filtered.length})")),
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
                isSelected: _selectedRol == null,
                onSelected: (_) => setState(() {
                  _selectedRol = null;
                  _applyFilters();
                }),
              ),
              ..._roles.map((r) => FilterChipData(
                label: r,
                isSelected: _selectedRol == r,
                onSelected: (_) => setState(() {
                  _selectedRol = _selectedRol == r ? null : r;
                  _applyFilters();
                }),
              )),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text("No se encontró personal con estos filtros"))
                    : RefreshIndicator(
                        onRefresh: _loadPersonal,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) => _buildPersonalCard(_filtered[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard(dynamic p) {
    final String rol = p['rol'] ?? 'Personal';
    final bool activo = p['estadoCuenta'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Icon(
            rol == 'Seguridad' ? Icons.security :
            rol == 'Coordinador' ? Icons.admin_panel_settings :
            Icons.badge,
            color: AppTheme.primary,
          ),
        ),
        title: Text(p['nombreUsuario'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("C.I: ${p['cedula']}"),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(rol, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Icon(activo ? Icons.check_circle : Icons.cancel, size: 14, color: activo ? Colors.green : Colors.grey),
                const SizedBox(width: 4),
                Text(activo ? "Activo" : "Inactivo", style: TextStyle(fontSize: 11, color: activo ? Colors.green : Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline, color: AppTheme.primary),
          onPressed: () => _showPersonalDetail(p),
        ),
      ),
    );
  }

  void _showPersonalDetail(dynamic p) {
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
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.person, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(p['nombreUsuario'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(p['rol'], style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            _detailRow(Icons.badge, "Cédula", p['cedula']),
            _detailRow(Icons.phone, "Teléfono", p['telefono'] ?? "No registrado"),
            const SizedBox(height: 24),
            const Text(
              "Gestión de imagen de perfil próximamente...",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
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
}
