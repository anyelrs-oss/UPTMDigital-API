import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/services/supabase_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/inbox_screen.dart';
import 'package:uptmdigital_app/screens/noticias_list_screen.dart';
import 'package:uptmdigital_app/widgets/anuncios_carousel.dart';
import 'package:uptmdigital_app/widgets/student_progress.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';
import 'package:uptmdigital_app/widgets/upcoming_evaluations.dart';
import 'package:uptmdigital_app/screens/carnet_screen.dart';
import 'package:uptmdigital_app/screens/my_grades_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';


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
    final api = ApiService();

    // 1. Intentar cargar de caché primero para rapidez
    final cached = await api.storage.read(key: 'cached_user_me');
    if (cached != null && mounted) {
      setState(() {
        _studentData = jsonDecode(cached);
        _isLoading = false;
      });
    }

    // 2. Cargar de la red en segundo plano para actualizar
    final data = await api.getUserMe();
    
    // Si getUserMe no tiene el perfil (Fase 8: fallback por si el backend no linkeó bien /me)
    if (mounted && data != null && data['idEstudiante'] == null) {
      debugPrint("Dashboard: idEstudiante null en /me, intentando /estudiantes/me");
      final studentProfile = await api.getStudentMe();
      if (studentProfile != null) {
        data.addAll(studentProfile);
        // Volver a guardar en caché con el perfil completo
        await api.storage.write(key: 'cached_user_me', value: jsonEncode(data));
      }
    }

    if (mounted && data != null) {
      setState(() {
        _studentData = data;
        _isLoading = false;
      });
    } else if (mounted && _studentData == null) {
      // Solo marcamos como no cargando si no había caché y falló la red
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

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    setState(() => _isLoading = true);

    final file = File(image.path);
    final idEstudiante = _studentData!['idEstudiante'];
    if (idEstudiante == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: ID de estudiante no encontrado")));
      setState(() => _isLoading = false);
      return;
    }
    final fileName = "profile_std_$idEstudiante.jpg";

    final url = await SupabaseService().uploadImage(file, fileName);

    if (url != null) {
      final success = await ApiService().updateStudent(_studentData!['idEstudiante'], {
        ..._studentData!,
        'fotoUrl': url
      });

      if (success) {
        _loadStudentData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto de perfil actualizada")));
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al subir imagen")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final studentId = _studentData?['idEstudiante'];
    if (studentId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error de Perfil")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  "Tu usuario no tiene un perfil de estudiante vinculado o hubo un error al cargar los datos.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                if (_studentData != null) ...[
                   const SizedBox(height: 8),
                   Text(
                     "ID Usuario: ${_studentData!['idUsuario']} | Cédula: ${_studentData!['cedula']}",
                     style: const TextStyle(fontSize: 12, color: Colors.grey),
                   ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _loadStudentData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reintentar"),
                ),
                TextButton(
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
        // Cargar Notas del Estudiante (Me)
        activePage = const MyGradesScreen();
        title = "Mis Calificaciones";
        break;
      case 2:
        // Carnet movido fuera del menú
        activePage = CarnetScreen(userData: {..._studentData!, 'rol': 'Estudiante'});
        title = "Carnet Digital";
        break;
      case 3:
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
            _buildNavItem(1, Icons.grade_outlined, "Notas"),
            const SizedBox(width: 48), // The space for the FAB
            _buildNavItem(2, Icons.badge_outlined, "Carnet"),
            _buildNavItem(3, Icons.person_outline, "Perfil"),
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
                  fontSize: 10,
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
      padding: const EdgeInsets.only(bottom: 100, top: 16, left: 16, right: 16),
      children: [


        // 1. Academic Status Banner (Fase 8)
        if (!(_studentData!['estadoArancel'] ?? true))
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade300)),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 12),
                Expanded(child: Text("Periodo Inactivo. Pendiente por pago de aranceles.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),

        // 2. Academic Progress
        InstitutionalCard(
          title: "Mi Progreso",
          child: StudentProgress(studentId: _studentData!['idEstudiante']),
        ),

        // 3. Upcoming Evaluations
        InstitutionalCard(
          title: "Próximas Evaluaciones",
          child: UpcomingEvaluations(studentId: _studentData!['idEstudiante']),
        ),

        // 4. News / Announcements
        InstitutionalCard(
          title: "Noticias Institucionales",
          padding: EdgeInsets.zero, // Carousel handles its own padding
          child: Column(
            children: [
               const SizedBox(height: 8),
               const AnunciosCarousel(),
               const SizedBox(height: 16),
               TextButton(
                 onPressed: () {
                   setState(() {
                     // El menu FAB tiene noticias, pero si queremos navegar desde aquí:
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticiasListScreen()));
                   });
                 },
                 child: const Text("Ver todas las noticias"),
               ),
            ],
          ),
        ),
      ],
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
               Stack(
                 children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundImage: (_studentData!['fotoUrl'] != null && _studentData!['fotoUrl'].toString().isNotEmpty)
                        ? NetworkImage(_studentData!['fotoUrl'])
                        : null,
                    child: (_studentData!['fotoUrl'] == null || _studentData!['fotoUrl'].toString().isEmpty)
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: _pickProfileImage,
                      ),
                    ),
                  ),
                 ],
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
    final direccionController = TextEditingController(text: _studentData!['direccion']);
    final telefonoController = TextEditingController(text: _studentData!['telefono']);
    final correoController = TextEditingController(text: _studentData!['correoInstitucional']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: direccionController,
              decoration: const InputDecoration(labelText: "Dirección"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: "Teléfono"),
            ),
            const SizedBox(height: 8),
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
                ..._studentData!,
                "direccion": direccionController.text,
                "telefono": telefonoController.text,
                "correoInstitucional": correoController.text,
              };
              
              final success = await ApiService().updateStudent(_studentData!['idEstudiante'], updatedData);
              if (!mounted) return;
              if (success) {
                 if (ctx.mounted) Navigator.pop(ctx);
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
