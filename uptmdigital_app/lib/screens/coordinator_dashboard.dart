import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/inbox_screen.dart';
import 'package:uptmdigital_app/screens/anuncios_admin_screen.dart';

import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _coordData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ApiService().getUserMe();
    if (mounted) {
      setState(() {
        _coordData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Widget activePage;
    String title = "Panel de Coordinación";

    switch (_currentIndex) {
      case 0: activePage = _buildHomeTab(); break;
      case 1: activePage = const InboxScreen(); title = "Comunicación"; break;
      case 2: activePage = const Center(child: Text("Gestión de Horarios (Excel)")); title = "Horarios"; break;
      default: activePage = _buildHomeTab();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
        ],
      ),
      body: activePage,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => MenuBottomSheet(role: 'coordinator', userData: _coordData),
          );
        },
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.apps, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItemSimple(Icons.home, "Inicio", 0),
            const SizedBox(width: 48), // FAB
            _buildNavItemSimple(Icons.chat, "Chats", 1),
            _buildNavItemSimple(Icons.calendar_month, "Horarios", 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemSimple(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : Colors.grey),
            Text(label, style: TextStyle(fontSize: 10, color: isSelected ? AppTheme.primary : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InstitutionalCard(
          title: "Mi Carrera",
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.school)),
            title: Text(_coordData?['carrera']?['nombre'] ?? "Carrera no asignada"),
            subtitle: const Text("Coordinador Académico"),
          ),
        ),
        _buildPinGenerator(),
        const SizedBox(height: 10),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildPinGenerator() {
    return InstitutionalCard(
      title: "Asistencia Diaria",
      child: Column(
        children: [
          const Text("Genere el PIN diario para los profesores de su carrera.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generarPin,
            icon: const Icon(Icons.vibration),
            label: const Text("GENERAR PIN DE HOY"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _ActionCard(icon: Icons.campaign, label: "Crear Anuncio", color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnunciosAdminScreen()))),
        _ActionCard(icon: Icons.groups, label: "Mis Voceros", color: Colors.blue, onTap: () {}),
      ],
    );
  }

  void _generarPin() async {
    final res = await ApiService().generarPinAsistencia(_coordData?['carreraId']);
    final pin = res['pin'];
    if (mounted && pin != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key, color: AppTheme.primary),
              SizedBox(width: 10),
              Text("PIN de Asistencia", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Este PIN es válido para la asistencia de hoy en los docentes de su carrera.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200, width: 1.5),
                ),
                child: Text(
                  pin,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text("Copiar"),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: pin));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PIN copiado al portapapeles")),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text("Enviar Chat"),
                    onPressed: () async {
                      final coordName = "${_coordData?['nombres'] ?? ''} ${_coordData?['apellidos'] ?? ''}".trim();
                      final success = await ApiService().sendMensaje({
                        "CarreraId": _coordData?['carreraId'],
                        "Contenido": "Hola profesores, el PIN de asistencia para el día de hoy es: $pin",
                        "TipoChat": "Carrera",
                        "EmisorNombre": coordName.isNotEmpty ? coordName : (_coordData?['nombreUsuario'] ?? "Coordinador"),
                      });
                      if (success) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("PIN compartido en el chat de la carrera")),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error al enviar el PIN al chat")),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al generar el PIN de asistencia.")),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Deseas salir del panel de coordinación?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService().logout();
              if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Salir"),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
