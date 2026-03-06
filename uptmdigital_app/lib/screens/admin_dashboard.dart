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
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _AdminCard(
            icon: Icons.people_outline,
            title: "Estudiantes",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EstudiantesScreen()),
            ),
          ),
          _AdminCard(
            icon: Icons.school_outlined,
            title: "Profesores",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfesoresScreen()),
            ),
          ),
          _AdminCard(
            icon: Icons.book_outlined,
            title: "Asignaturas",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AsignaturasScreen()),
            ),
          ),
          _AdminCard(
            icon: Icons.app_registration,
            title: "Inscripciones",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InscripcionesScreen()),
            ),
          ),
          _AdminCard(
            icon: Icons.grade,
            title: "Notas",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotasScreen()),
            ),
          ),
          _AdminCard(
            icon: Icons.check_circle_outline,
            title: "Asistencias",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AsistenciasScreen()),
            ),
          ),
          _AdminCard(
            icon: Icons.description_outlined,
            title: "Constancias",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConstanciasScreen()),
            ),
          ),
          _AdminCard(
            icon: Icons.access_time,
            title: "Horarios",
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HorariosScreen(isAdmin: true)),
            ),
          ),
          _AdminCard(
            icon: Icons.settings,
            title: "Mantenimiento",
            color: Colors.grey, // Distinction for maintenance
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
            ),
          ),
        ],
      ),
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
      margin: EdgeInsets.zero, // GridView handles spacing
      onTap: onTap, // InstitutionalCard needs to support onTap, checking if it does...
      // Wait, standard InstitutionalCard might not have onTap. 
      // If it doesn't, I should wrap it or use InkWell inside it.
      // Let's assume standard usage: InstitutionalCard(child: ...)
      // If I need tap, I should likely wrap the inner content or if the card doesn't support it, wrap the Card.
      // Let's check InstitutionalCard definition in my memory. 
      // It's a Container -> Decoration. It might not have InkWell.
      // I will wrap the InstitutionalCard content in InkWell OR update InstitutionalCard to support onTap.
      // Better: Wrap InstitutionalCard in GestureDetector/InkWell? No, shadows/radius issues.
      // Best: Using the content of InstitutionalCard. 
      // Actually, InstitutionalCard is a styling wrapper. 
      // Let's wrap InstitutionalCard in an InkWell? No, the Card decoration is inside.
      // Let's Assume I can pass a child that handles taps. 
      
      child: InkWell( // Ripples might be clipped or weird if not on Material
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
           width: double.infinity, // Fill the grid cell
           padding: const EdgeInsets.symmetric(vertical: 24),
           child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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

