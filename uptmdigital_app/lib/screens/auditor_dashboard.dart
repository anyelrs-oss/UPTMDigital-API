import 'package:flutter/material.dart';
import 'package:uptmdigital_app/screens/auditoria_main_screen.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/theme.dart';

import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';

class AuditorDashboard extends StatefulWidget {
  const AuditorDashboard({super.key});

  @override
  State<AuditorDashboard> createState() => _AuditorDashboardState();
}

class _AuditorDashboardState extends State<AuditorDashboard> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await ApiService().getUserMe();
    if (mounted) {
      setState(() {
        _userData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primary,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Panel de Auditoría"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            )
          ],
        ),
        body: const AuditoriaMainScreen(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => MenuBottomSheet(role: 'auditor', userData: _userData),
            );
          },
          backgroundColor: AppTheme.secondary,
          child: const Icon(Icons.apps, color: Colors.white),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Deseas salir del panel de auditoría?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Salir"),
          ),
        ],
      ),
    );
  }
}
