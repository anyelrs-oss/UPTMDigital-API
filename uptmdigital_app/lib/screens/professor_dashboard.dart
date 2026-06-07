import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
// Reuse for now, will filter later
import 'package:uptmdigital_app/screens/notas_screen.dart';
import 'package:uptmdigital_app/screens/asistencias_screen.dart';
import 'package:uptmdigital_app/widgets/anuncios_carousel.dart';
import 'package:uptmdigital_app/services/notification_service.dart';
 // For Clipboard
import 'package:uptmdigital_app/screens/horarios_screen.dart';
import 'package:uptmdigital_app/screens/inbox_screen.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';
import 'dart:convert';



class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({super.key});

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _professorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessorData();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final ns = NotificationService();
    await ns.initialize();
  }

  Future<void> _loadProfessorData() async {
    final api = ApiService();

    // 1. Cargar de caché primero
    final cached = await api.storage.read(key: 'cached_user_me');
    if (cached != null && mounted) {
      setState(() {
        _professorData = jsonDecode(cached);
        _isLoading = false;
      });
    }

    // 2. Cargar de red para actualizar
    final data = await api.getUserMe();
    if (mounted && data != null) {
      setState(() {
        _professorData = data;
        _isLoading = false;
      });
    } else if (mounted && _professorData == null) {
      setState(() {
        _isLoading = false;
      });
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_professorData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Error al cargar perfil."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await ApiService().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: const Text("Cerrar Sesión"),
              ),
            ],
          ),
        ),
      );
    }

    // Determine the active page
    Widget activePage;
    
    // Logic to map index to pages, skipping the FAB index (2) if strictly following the pattern,
    // but here we have 4 main items + FAB.
    // Let's look at the nav items: 
    // Left: Home (0), Asignaturas (1)
    // FAB
    // Right: Notas (2 -> mapped to index 3 internally?), Asistencia (3 -> mapped to index 4?)
    // Actually, I can just use a unified index logic if I want.
    // Let's use:
    // 0: Home
    // 1: Asignaturas
    // 2: FAB (Floating) - logic usually skips this.
    // 3: Notas
    // 4: Asistencia
    
    switch (_currentIndex) {
      case 0:
        activePage = _buildHomeTab();
        break;
      case 1:
        activePage = const HorariosScreen(isAdmin: false);
        break;
      case 2:
        activePage = const InboxScreen(); // Real Inbox
        break;
      case 3:
        activePage = const NotasScreen();
        break;
      case 4:
        activePage = const AsistenciasScreen();
        break;
      default:
        activePage = _buildHomeTab();
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text("Prof. ${_professorData!['nombres']} ${_professorData!['apellidos']}"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: activePage,
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => MenuBottomSheet(role: 'professor', userData: _professorData),
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
            _buildNavItem(Icons.home_outlined, "Inicio", 0),
            _buildNavItem(Icons.calendar_today_outlined, "Horario", 1),
            const SizedBox(width: 40), // FAB Space
            _buildNavItem(Icons.chat_bubble_outline, "Chats", 2),
            _buildNavItem(Icons.grade_outlined, "Notas", 3),
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

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Identity / Welcome Card
        InstitutionalCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                backgroundImage: _professorData!['fotoUrl'] != null ? NetworkImage(_professorData!['fotoUrl']) : null,
                child: _professorData!['fotoUrl'] == null 
                    ? Text(_professorData!['nombres'][0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondary))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prof. ${_professorData!['nombres']} ${_professorData!['apellidos']}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _professorData!['departamento'] ?? 'Departamento General',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              IconButton( // Settings/Profile Shortcut
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: _showEditProfileDialog,
              )
            ],
          ),
        ),



        // 3. News
        InstitutionalCard(
          title: "Noticias Institucionales",
          padding: EdgeInsets.zero, // Carousel handles padding or full width
          child: const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: AnunciosCarousel(),
          ),
        ),
      ],
    );
  }


  void _showEditProfileDialog() {
    final telefonoController = TextEditingController(text: _professorData!['telefono']);
    final correoController = TextEditingController(text: _professorData!['correoInstitucional']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: "Teléfono"),
            ),
            TextField(
              controller: correoController,
              decoration: const InputDecoration(labelText: "Correo Institucional"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedData = {
                ..._professorData!,
                "telefono": telefonoController.text,
                "correoInstitucional": correoController.text,
              };
              
              final success = await ApiService().updateProfesor(_professorData!['idProfesor'], updatedData);
              if (!mounted) return;
              if (success) {
                 if (ctx.mounted) Navigator.pop(ctx);
                 _loadProfessorData(); // Refresh
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar perfil")));
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
