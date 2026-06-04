import 'package:flutter/material.dart';
import 'package:uptmdigital_app/screens/audit_logs_screen.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class AuditoriaMainScreen extends StatelessWidget {
  const AuditoriaMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primary,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F)),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text("Centro de Auditoría")),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Monitoreo de seguridad y actividad del sistema.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _AuditOption(
              icon: Icons.map_outlined,
              title: "Bitácora de Ruta",
              subtitle: "Seguimiento de navegación y acceso a recursos.",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen(filterAction: 'GET'))),
            ),
            const SizedBox(height: 16),
            _AuditOption(
              icon: Icons.edit_attributes_outlined,
              title: "Bitácora de Acciones",
              subtitle: "Registro de cambios, creaciones y eliminaciones.",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AuditOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InstitutionalCard(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: AppTheme.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
