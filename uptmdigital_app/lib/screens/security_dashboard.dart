import 'package:flutter/material.dart';
import 'package:uptmdigital_app/screens/security_qr_screen.dart';
import 'package:uptmdigital_app/screens/classroom_opening_screen.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';
import 'package:uptmdigital_app/screens/security_checklist_screen.dart';
import 'dart:async';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  int _currentIndex = 0;
  List<dynamic> _solicitudes = [];
  List<dynamic> _historial = [];
  bool _isLoadingSolicitudes = false;
  bool _isLoadingHistorial = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Wake up server immediately if not already done
    ApiService().getHealth();
    _loadAllData();
    _startPolling();
  }

  void _loadAllData() {
    _loadSolicitudes();
    _loadHistorial();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentIndex == 0) _loadSolicitudes();
      if (_currentIndex == 1) _loadHistorial();
    });
  }

  Future<void> _loadHistorial() async {
    if (_isLoadingHistorial) return;
    setState(() => _isLoadingHistorial = true);
    final data = await ApiService().getHistorialAccesos();
    if (mounted) {
      setState(() {
        _historial = data;
        _isLoadingHistorial = false;
      });
    }
  }

  Future<void> _loadSolicitudes() async {
    if (_isLoadingSolicitudes) return;

    // Attempt to load from cache first if we want, but requests need real-time data.
    // However, we can at least show a loading indicator ONLY if it's the first load.
    final isFirstLoad = _solicitudes.isEmpty;
    if (isFirstLoad) setState(() => _isLoadingSolicitudes = true);

    try {
      // Run both requests in parallel to save time
      final results = await Future.wait([
        ApiService().getSolicitudesApertura(estado: 'Pendiente'),
        ApiService().getSolicitudesApertura(estado: 'EnCamino'),
      ]);

      if (mounted) {
        setState(() {
          _solicitudes = [...results[0], ...results[1]];
          _isLoadingSolicitudes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSolicitudes = false);
    }
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
    // Determine active page based on index
    Widget activePage;
    String title = "Panel de Seguridad";

    switch (_currentIndex) {
      case 0:
        activePage = _buildDashboardTab();
        title = "Control de Acceso";
        break;
      case 1:
        activePage = _buildHistoryTab();
        title = "Historial";
        break;
      case 3:
        activePage = _buildReportsTab();
        title = "Reportes";
        break;
      case 4:
        activePage = _buildSettingsTab();
        title = "Configuración";
        break;
      default:
        activePage = _buildDashboardTab();
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.jpg', height: 40),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Implement notifications
            },
            tooltip: "Notificaciones",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
            tooltip: "Cerrar Sesión",
          ),
        ],
      ),
      body: activePage,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => const MenuBottomSheet(role: 'security'),
          );
        },
        backgroundColor: AppTheme.secondary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.security, "Control", 0),
            _buildNavItem(Icons.history, "Historial", 1),
            const SizedBox(width: 40), // FAB Space
            _buildNavItem(Icons.bar_chart, "Reportes", 3),
            _buildNavItem(Icons.settings, "Config", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey,
              size: 26,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadAllData();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100, top: 16),
        children: [
          // Solicitudes de Apertura Card
          InstitutionalCard(
            title: "Solicitudes de Apertura",
            trailing: _isLoadingSolicitudes
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSolicitudes),
            child: _solicitudes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No hay solicitudes pendientes", style: TextStyle(color: Colors.grey))),
                )
              : Column(
                  children: _solicitudes.map((s) => _buildSolicitudItem(s)).toList(),
                ),
          ),

          // Quick Access Card
          InstitutionalCard(
            title: "Acceso Rápido",
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, size: 30),
                    label: const Text(
                      "ESCANEAR QR",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SecurityQRScreen()),
                      ).then((_) => _loadAllData());
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.meeting_room, size: 30),
                    label: const Text(
                      "APERTURA DE AULAS",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClassroomOpeningScreen()),
                      ).then((_) => _loadAllData());
                    },
                  ),
                ),
              ],
            ),
          ),

          // Stats Card
          InstitutionalCard(
            title: "Estadísticas del Día",
            child: Column(
              children: [
                _buildStatRow("Movimientos Totales", "${_historial.length}", Icons.analytics, AppTheme.primary),
                const SizedBox(height: 12),
                _buildStatRow("Entradas Registradas", "${_historial.where((h) => h['tipo'] == 'Entrada').length}", Icons.login, Colors.green),
                const SizedBox(height: 12),
                _buildStatRow("Aperturas de Aulas", "${_historial.where((h) => h['tipo'] == 'Apertura').length}", Icons.key, Colors.blue),
              ],
            ),
          ),

          // Recent Activity Card
          InstitutionalCard(
            title: "Actividad Reciente",
            trailing: TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text("Ver Más"),
            ),
            child: _historial.isEmpty
                ? const Center(child: Text("Sin movimientos recientes", style: TextStyle(color: Colors.grey)))
                : Column(
                    children: _historial.take(3).map((h) {
                      final bool isEntry = h['tipo'] == 'Entrada' || h['tipo'] == 'Apertura';
                      return Column(
                        children: [
                          _buildActivityItem(
                            h['nombre'] ?? "Usuario",
                            "${h['tipo']} - ${h['ubicacion'] ?? 'Campus'}",
                            _formatTime(h['fechaHora']),
                            isEntry,
                            rol: h['rol'],
                          ),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudItem(dynamic s) {
    final bool isEnCamino = s['estado'] == 'EnCamino';
    final String aulaNombre = s['aula']?['nombre'] ?? 'Aula';
    final String profesorNombre = s['profesor'] != null
        ? "${s['profesor']['nombres']} ${s['profesor']['apellidos']}"
        : "Profesor";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isEnCamino ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnCamino ? Icons.directions_run : Icons.priority_high,
                  color: isEnCamino ? Colors.blue : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Apertura: $aulaNombre",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      profesorNombre,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                s['estado'],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isEnCamino ? Colors.blue : Colors.orange
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!isEnCamino)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await ApiService().marcarEnCamino(s['idSolicitud']);
                      if (success) _loadSolicitudes();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text("Voy en camino"),
                  ),
                ),
              if (isEnCamino)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SecurityChecklistScreen(
                          solicitudId: s['idSolicitud'],
                          aulaNombre: aulaNombre,
                        )
                      )).then((_) => _loadSolicitudes());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text("Realizar Chequeo"),
                  ),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String name, String action, String time, bool isEntry, {String? rol}) {
    IconData rolIcon = rol == 'Profesor' ? Icons.school : Icons.person_outline;
    if (action.contains("Apertura")) rolIcon = Icons.vpn_key;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isEntry ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            child: Icon(rolIcon, color: isEntry ? Colors.green : Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "$action ${rol != null ? '($rol)' : ''}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return "Ahora";
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return "Hace ${diff.inMinutes}m";
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadHistorial,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100, top: 16),
        children: [
          InstitutionalCard(
            title: "Historial de Accesos Globales",
            child: _isLoadingHistorial && _historial.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _historial.isEmpty
                ? const Center(child: Text("No hay registros en la base de datos"))
                : Column(
                    children: _historial.map((h) {
                      final bool isEntry = h['tipo'] == 'Entrada' || h['tipo'] == 'Apertura';
                      return Column(
                        children: [
                          _buildActivityItem(
                            h['nombre'] ?? "Usuario",
                            "${h['tipo']} - ${h['ubicacion'] ?? 'Campus'}",
                            _formatTime(h['fechaHora']),
                            isEntry,
                            rol: h['rol'],
                          ),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: InstitutionalCard(
          title: "Reportes",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart, size: 80, color: AppTheme.primary),
              const SizedBox(height: 20),
              const Text(
                "Módulo de Reportes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Funcionalidad en desarrollo",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: InstitutionalCard(
          title: "Configuración",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings, size: 80, color: AppTheme.primary),
              const SizedBox(height: 20),
              const Text(
                "Configuración de Seguridad",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Funcionalidad en desarrollo",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
