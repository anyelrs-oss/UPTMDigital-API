import 'package:flutter/material.dart';
import 'package:uptmdigital_app/screens/security_qr_screen.dart';
import 'package:uptmdigital_app/screens/classroom_opening_screen.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  int _currentIndex = 0;

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
            onPressed: () async {
              await ApiService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      children: [
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
                    );
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
                    );
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
              _buildStatRow("Entradas Registradas", "24", Icons.login, Colors.green),
              const SizedBox(height: 12),
              _buildStatRow("Salidas Registradas", "18", Icons.logout, Colors.orange),
              const SizedBox(height: 12),
              _buildStatRow("Personas en Campus", "6", Icons.people, AppTheme.primary),
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
          child: Column(
            children: [
              _buildActivityItem("Juan Pérez", "Entrada", "10:30 AM", true),
              const Divider(),
              _buildActivityItem("María González", "Salida", "10:25 AM", false),
              const Divider(),
              _buildActivityItem("Carlos Ruiz", "Entrada", "10:20 AM", true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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

  Widget _buildActivityItem(String name, String action, String time, bool isEntry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isEntry ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Icon(
              isEntry ? Icons.arrow_downward : Icons.arrow_upward,
              color: isEntry ? Colors.green : Colors.orange,
              size: 20,
            ),
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
                  action,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      children: [
        InstitutionalCard(
          title: "Historial de Accesos",
          child: Column(
            children: List.generate(
              10,
              (index) => Column(
                children: [
                  _buildActivityItem(
                    "Usuario ${index + 1}",
                    index % 2 == 0 ? "Entrada" : "Salida",
                    "${10 + index}:${30 - index * 2} AM",
                    index % 2 == 0,
                  ),
                  if (index < 9) const Divider(),
                ],
              ),
            ),
          ),
        ),
      ],
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
