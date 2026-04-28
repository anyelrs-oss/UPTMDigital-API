import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/estudiantes_screen.dart';
import 'package:uptmdigital_app/screens/profesores_screen.dart';
import 'package:uptmdigital_app/screens/asignaturas_screen.dart';
import 'package:uptmdigital_app/screens/inscripciones_screen.dart';
import 'package:uptmdigital_app/screens/notas_screen.dart';
import 'package:uptmdigital_app/screens/asistencias_screen.dart';
import 'package:uptmdigital_app/screens/constancias_screen.dart';
import 'package:uptmdigital_app/screens/admin_maintenance_screen.dart';
import 'package:uptmdigital_app/screens/horarios_screen.dart';
import 'package:uptmdigital_app/screens/usuarios_screen.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.jpg', height: 40),
            const SizedBox(width: 8),
            const Text("Panel de Administrador"),
          ],
        ),
        actions: [
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
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- PERSONAS ---
          _SectionHeader(icon: Icons.people, title: "Personas"),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _AdminCard(
                icon: Icons.manage_accounts,
                title: "Usuarios",
                color: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuariosScreen())),
              ),
              _AdminCard(
                icon: Icons.people_outline,
                title: "Estudiantes",
                color: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EstudiantesScreen())),
              ),
              _AdminCard(
                icon: Icons.school_outlined,
                title: "Profesores",
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfesoresScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- ACADÉMICO ---
          _SectionHeader(icon: Icons.menu_book, title: "Académico"),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _AdminCard(
                icon: Icons.book_outlined,
                title: "Asignaturas",
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsignaturasScreen())),
              ),
              _AdminCard(
                icon: Icons.app_registration,
                title: "Inscripciones",
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InscripcionesScreen())),
              ),
              _AdminCard(
                icon: Icons.grade,
                title: "Notas",
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotasScreen())),
              ),
              _AdminCard(
                icon: Icons.check_circle_outline,
                title: "Asistencias",
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsistenciasScreen())),
              ),
              _AdminCard(
                icon: Icons.access_time,
                title: "Horarios",
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HorariosScreen(isAdmin: true))),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- SERVICIOS ---
          _SectionHeader(icon: Icons.miscellaneous_services, title: "Servicios"),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _AdminCard(
                icon: Icons.description_outlined,
                title: "Constancias",
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConstanciasScreen())),
              ),
              _AdminCard(
                icon: Icons.settings,
                title: "Mantenimiento",
                color: Colors.grey,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen())),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InstitutionalCard(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
           width: double.infinity,
           padding: const EdgeInsets.symmetric(vertical: 16),
           child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
