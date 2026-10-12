import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/reporte_asistencia_docente_screen.dart';
import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';
import 'dart:convert';
import 'package:uptmdigital_app/services/notification_service.dart';
import 'package:uptmdigital_app/widgets/notification_bell_button.dart';

class SecretariaDashboard extends StatefulWidget {
  const SecretariaDashboard({super.key});

  @override
  State<SecretariaDashboard> createState() => _SecretariaDashboardState();
}

class _SecretariaDashboardState extends State<SecretariaDashboard> {
  final _cedulaCtrl = TextEditingController();
  final _facturaCtrl = TextEditingController();
  final _expedienteCedulaCtrl = TextEditingController();
  bool _isOfflineMode = false;
  List<Map<String, String>> _pendingSync = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  // Daree data
  Map<String, dynamic>? _periodoActivo;
  Map<String, dynamic>? _expedienteResult;
  bool _isSearchingExpediente = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
    _loadUserData();
    _loadDareeData();
    NotificationService().initialize();
  }

  Future<void> _loadUserData() async {
    final data = await ApiService().getUserMe();
    if (mounted) {
      setState(() {
        _userData = data;
      });
    }
  }

  Future<void> _loadDareeData() async {
    try {
      final periodo = await ApiService().getDareePeriodoActivo();
      if (mounted && periodo != null) {
        setState(() => _periodoActivo = periodo);
      }
    } catch (e) {
      debugPrint('Secretaria Daree load error: $e');
    }
  }

  Future<void> _buscarExpediente() async {
    final cedula = _expedienteCedulaCtrl.text.trim();
    if (cedula.isEmpty) return;
    setState(() {
      _isSearchingExpediente = true;
      _expedienteResult = null;
    });
    try {
      final result = await ApiService().getDareeDocenteDetalle(cedula);
      // Try student profile too
      // For now use docente endpoint which searches by cedula across the DB
      if (mounted) {
        setState(() {
          _expedienteResult = result;
          _isSearchingExpediente = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearchingExpediente = false);
    }
  }

  Future<void> _loadOfflineData() async {
    final api = ApiService();
    final cached = await api.storage.read(key: 'pending_aranceles');
    if (cached != null) {
      setState(() {
        _pendingSync = List<Map<String, String>>.from(
          (jsonDecode(cached) as List).map((e) => Map<String, String>.from(e))
        );
      });
    }
  }

  Future<void> _processValidation() async {
    if (_cedulaCtrl.text.isEmpty || _facturaCtrl.text.isEmpty) return;

    final data = {
      'cedula': _cedulaCtrl.text,
      'factura': _facturaCtrl.text,
      'fecha': DateTime.now().toIso8601String(),
    };

    if (_isOfflineMode) {
      setState(() {
        _pendingSync.add(data);
        _cedulaCtrl.clear();
        _facturaCtrl.clear();
      });
      _saveOfflineData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardado localmente (Modo Apagón)")));
    } else {
      setState(() => _isLoading = true);
      final success = await ApiService().validarArancel(data['cedula']!, data['factura']!);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _cedulaCtrl.clear();
        _facturaCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Validación exitosa")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión. Active Modo Apagón."), backgroundColor: Colors.orange));
      }
    }
  }

  Future<void> _saveOfflineData() async {
    final api = ApiService();
    await api.storage.write(key: 'pending_aranceles', value: jsonEncode(_pendingSync));
  }

  Future<void> _syncData() async {
    if (_pendingSync.isEmpty) return;
    setState(() => _isLoading = true);

    int successCount = 0;
    List<Map<String, String>> failed = [];

    for (var item in _pendingSync) {
      final res = await ApiService().validarArancel(item['cedula']!, item['factura']!);
      if (res) {
        successCount++;
      } else {
        failed.add(item);
      }
    }

    if (!mounted) return;
    setState(() {
      _pendingSync = failed;
      _isLoading = false;
    });
    _saveOfflineData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sincronizados: $successCount, Fallidos: ${failed.length}")));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir de tu cuenta?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService().logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Cerrar Sesión"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portal de Secretaría"),
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBellButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
          Switch(
            value: _isOfflineMode,
            onChanged: (val) => setState(() => _isOfflineMode = val),
            activeColor: Colors.redAccent,
          ),
          const Center(child: Text("Modo Apagón  ", style: TextStyle(fontSize: 10))),
        ],
      ),
      body: Column(
        children: [
          if (_isOfflineMode)
            Container(
              width: double.infinity,
              color: Colors.redAccent.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text("TRABAJANDO SIN CONEXIÓN", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InstitutionalCard(
                  title: "Validación de Aranceles",
                  child: Column(
                    children: [
                      TextField(controller: _cedulaCtrl, decoration: const InputDecoration(labelText: "Cédula del Estudiante")),
                      const SizedBox(height: 12),
                      TextField(controller: _facturaCtrl, decoration: const InputDecoration(labelText: "Número de Factura")),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _processValidation,
                          style: ElevatedButton.styleFrom(backgroundColor: _isOfflineMode ? Colors.orange : AppTheme.primary, foregroundColor: Colors.white),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTRAR PAGO"),
                        ),
                      ),
                    ],
                  ),
                ),

                // Periodo Activo (Daree)
                if (_periodoActivo != null)
                  InstitutionalCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today, color: AppTheme.secondary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Periodo Activo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                _periodoActivo!['nombre'] ?? _periodoActivo!['codigo'] ?? 'Sin periodo',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _periodoActivo!['fase'] ?? '',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Consulta de Expediente (Daree)
                InstitutionalCard(
                  title: "Consulta de Expediente",
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expedienteCedulaCtrl,
                              decoration: const InputDecoration(
                                labelText: "Cédula a consultar",
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _buscarExpediente(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSearchingExpediente ? null : _buscarExpediente,
                            child: _isSearchingExpediente 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text("BUSCAR"),
                          ),
                        ],
                      ),
                      if (_expedienteResult != null && _expedienteResult!['data'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_expedienteResult!['data']['nombres'] ?? ''} ${_expedienteResult!['data']['apellidos'] ?? ''}".trim(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              if (_expedienteResult!['data']['profesion'] != null)
                                Text("Profesión: ${_expedienteResult!['data']['profesion']}", style: const TextStyle(fontSize: 12)),
                              if (_expedienteResult!['data']['especialidad'] != null)
                                Text("Especialidad: ${_expedienteResult!['data']['especialidad']}", style: const TextStyle(fontSize: 12)),
                              if (_expedienteResult!['data']['pnfNombre'] != null)
                                Text("PNF: ${_expedienteResult!['data']['pnfNombre']}", style: const TextStyle(fontSize: 12)),
                              if (_expedienteResult!['data']['correo'] != null)
                                Text("Correo: ${_expedienteResult!['data']['correo']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ] else if (_expedienteResult != null && _expedienteResult!['data'] == null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text("No se encontró registro con esa cédula.", style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                InstitutionalCard(
                  title: "Reportes Administrativos",
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.description, color: Colors.blue),
                        title: const Text("Asistencia Docente", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Resumen de cumplimiento de clases", style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReporteAsistenciaDocenteScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                if (_pendingSync.isNotEmpty)
                  InstitutionalCard(
                    title: "Pendientes por Sincronizar (${_pendingSync.length})",
                    child: Column(
                      children: [
                        ..._pendingSync.map((e) => ListTile(
                          title: Text(e['cedula']!),
                          subtitle: Text("Factura: ${e['factura']}"),
                          trailing: const Icon(Icons.cloud_off, color: Colors.grey),
                        )),
                        const Divider(),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _syncData,
                          icon: const Icon(Icons.sync),
                          label: const Text("Sincronizar ahora con el servidor"),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => MenuBottomSheet(role: 'secretaria', userData: _userData),
          );
        },
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.apps, color: Colors.white),
      ),
    );
  }
}
