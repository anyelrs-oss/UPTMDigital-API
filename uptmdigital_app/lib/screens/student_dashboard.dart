import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/constancias_screen.dart';
import 'package:uptmdigital_app/widgets/anuncios_carousel.dart';
import 'package:uptmdigital_app/widgets/student_progress.dart';
import 'package:uptmdigital_app/screens/carnet_screen.dart';
import 'package:uptmdigital_app/screens/qr_scan_screen.dart';
import 'package:uptmdigital_app/screens/horarios_screen.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';


class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final data = await ApiService().getStudentMe();
    if (mounted) {
      setState(() {
        _studentData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_studentData == null) {
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
    String title = "UPTM Digital";
    
    switch (_currentIndex) {
      case 0:
        activePage = _buildHomeTab();
        title = "UPTM Digital";
        break;
      case 1:
        activePage = HorariosScreen(studentId: _studentData!['idEstudiante']);
        title = "Mi Horario";
        break;
      case 3: // Index 3 because 2 is the space for FAB
        activePage = ConstanciasScreen(studentId: _studentData!['idEstudiante']);
        title = "Mis Constancias";
        break;
      case 4:
        activePage = _buildProfileTab();
        title = "Mi Perfil";
        break;
      default:
        activePage = _buildHomeTab();
    }

    return Scaffold(
      extendBody: true, // Important for the notch effect
      appBar: AppBar(
        title: Text(title),
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
            backgroundColor: Colors.transparent, // Important so rounded corners show
            builder: (context) => MenuBottomSheet(role: 'student', userData: _studentData),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.apps),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(0, Icons.home_outlined, "Inicio"),
            _buildNavItem(1, Icons.calendar_today_outlined, "Horario"),
            const SizedBox(width: 48), // The space for the FAB
            _buildNavItem(3, Icons.description_outlined, "Constancias"),
            _buildNavItem(4, Icons.person_outline, "Perfil"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                color: _currentIndex == index ? AppTheme.primary : Colors.grey,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _currentIndex == index ? AppTheme.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [


        // 2. Academic Progress
        InstitutionalCard(
          title: "Mi Progreso",
          child: StudentProgress(studentId: _studentData!['idEstudiante']),
        ),

        // 3. News / Announcements
        InstitutionalCard(
          title: "Noticias Institucionales",
          padding: EdgeInsets.zero, // Carousel handles its own padding
          child: Column(
            children: [
               const SizedBox(height: 8),
               const AnunciosCarousel(),
               const SizedBox(height: 16),
               TextButton(
                 onPressed: () {},
                 child: const Text("Ver todas las noticias"),
               ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        InstitutionalCard(
          child: Column(
             children: [
               const SizedBox(height: 16),
               const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              Text(
                "${_studentData!['nombres']} ${_studentData!['apellidos']}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                _studentData!['cedula'],
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit_outlined),
                label: const Text("Actualizar Datos"),
              ),
             ],
          ),
        ),

        InstitutionalCard(
          title: "Información Académica",
          child: Column(
            children: [
              _buildProfileRow("Carrera", _studentData!['carrera'] ?? "N/A"),
              _buildProfileRow("Semestre", "N/A"), // Placeholder
              _buildProfileRow("Índice", "N/A"), // Placeholder
            ],
          ),
        ),

        InstitutionalCard(
          title: "Información de Contacto",
          child: Column(
            children: [
              _buildProfileRow("Dirección", _studentData!['direccion'] ?? "N/A"),
              _buildProfileRow("Teléfono", _studentData!['telefono'] ?? "N/A"),
              _buildProfileRow("Correo", _studentData!['correoInstitucional'] ?? "N/A"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final _direccionController = TextEditingController(text: _studentData!['direccion']);
    final _telefonoController = TextEditingController(text: _studentData!['telefono']);
    final _correoController = TextEditingController(text: _studentData!['correoInstitucional']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: "Dirección"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: "Teléfono"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _correoController,
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
                ..._studentData!,
                "direccion": _direccionController.text,
                "telefono": _telefonoController.text,
                "correoInstitucional": _correoController.text,
              };
              
              final success = await ApiService().updateStudent(_studentData!['idEstudiante'], updatedData);
              if (success) {
                 Navigator.pop(ctx);
                 _loadStudentData(); // Refresh data
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
