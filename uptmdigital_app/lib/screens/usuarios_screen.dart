import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/widgets/search_filter_bar.dart';
import 'dart:convert';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _allUsuarios = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedRol;

  final _roles = ['Estudiante', 'Profesor', 'Seguridad', 'Administrador'];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() => _isLoading = true);
    final api = ApiService();

    // 1. Cargar de caché (solo primera carga sin filtros)
    if (_searchQuery.isEmpty && _selectedRol == null) {
      final cached = await api.storage.read(key: 'cached_usuarios_list');
      if (cached != null && mounted) {
        setState(() {
          _allUsuarios = jsonDecode(cached);
          _applyFilters();
          _isLoading = false;
        });
      }
    }

    // 2. Cargar de red
    final data = await api.getUsuarios(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      rol: _selectedRol,
    );
    if (mounted) {
      setState(() {
        _allUsuarios = data;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var result = _allUsuarios;

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

  Color _rolColor(String? rol) {
    switch (rol) {
      case 'Administrador': return Colors.purple;
      case 'Profesor': return Colors.blue;
      case 'Seguridad': return Colors.orange;
      case 'Estudiante': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Usuarios (${_filtered.length})")),
      body: Column(
        children: [
          SearchFilterBar(
            hintText: "Buscar por usuario o cédula...",
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
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                ? const Center(child: Text("No hay usuarios"))
                : RefreshIndicator(
                    onRefresh: _loadUsuarios,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic u) {
    final rol = u['rol'] ?? 'N/A';
    final activo = u['activo'] == true;
    final estadoCuenta = u['estadoCuenta'] == true;

    // Color basado en el estado de la cuenta (Habilitado/Bloqueado)
    final Color statusColor = estadoCuenta ? Colors.green : Colors.grey;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _rolColor(rol).withValues(alpha: 0.15),
              child: Icon(
                rol == 'Seguridad' ? Icons.security :
                rol == 'Profesor' ? Icons.school :
                rol == 'Administrador' ? Icons.admin_panel_settings :
                Icons.person,
                color: _rolColor(rol),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          u['nombreUsuario'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _rolColor(rol).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(rol, style: TextStyle(fontSize: 11, color: _rolColor(rol), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("C.I: ${u['cedula'] ?? 'N/A'}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(activo ? Icons.check_circle : Icons.cancel, size: 14, color: activo ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(activo ? "Activo" : "Inactivo", style: TextStyle(fontSize: 11, color: activo ? Colors.green : Colors.red)),
                      const SizedBox(width: 12),
                      Icon(estadoCuenta ? Icons.lock_open : Icons.lock, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        estadoCuenta ? "Habilitado" : "Bloqueado",
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(action, u),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(estadoCuenta ? Icons.block : Icons.check_circle, color: estadoCuenta ? Colors.orange : Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(estadoCuenta ? "Bloquear Usuario" : "Habilitar Usuario"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.password, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text("Nueva Contraseña"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, dynamic u) async {
    final id = u['idUsuario'];

    if (action == 'toggle') {
      final currentState = u['estadoCuenta'] == true;

      // Actualización Optimista: Cambiamos el estado en memoria inmediatamente
      setState(() {
        final index = _allUsuarios.indexWhere((element) => element['idUsuario'] == id);
        if (index != -1) {
          _allUsuarios[index]['estadoCuenta'] = !currentState;
          _applyFilters();
        }
      });

      final success = await ApiService().updateUsuario(id, {'estadoCuenta': !currentState});

      if (!success) {
        // Si falla, revertimos el cambio
        setState(() {
          final index = _allUsuarios.indexWhere((element) => element['idUsuario'] == id);
          if (index != -1) {
            _allUsuarios[index]['estadoCuenta'] = currentState;
            _applyFilters();
          }
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar usuario"), backgroundColor: Colors.red));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(!currentState ? "Usuario habilitado con éxito" : "Usuario bloqueado con éxito"),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } else if (action == 'reset') {
      final ctrl = TextEditingController();
      bool obscure = true;

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Nueva Contraseña"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Ingresa la nueva clave para ${u['nombreUsuario']}:"),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text("GUARDAR"),
              ),
            ],
          ),
        ),
      );

      if (result == true && ctrl.text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Procesando cambio...")));
        final success = await ApiService().resetPasswordUsuario(id, ctrl.text);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("¡Contraseña actualizada correctamente!"), backgroundColor: Colors.green));
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Error al cambiar contraseña"), backgroundColor: Colors.red));
        }
      }
    }
  }
}
