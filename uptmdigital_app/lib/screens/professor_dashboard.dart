import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/services/supabase_service.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/subject_selection_screen.dart';
import 'package:uptmdigital_app/screens/academic_hierarchy_screen.dart';
// Reuse for now, will filter later
import 'package:uptmdigital_app/screens/notas_screen.dart';
import 'package:uptmdigital_app/screens/asistencias_screen.dart';
import 'package:uptmdigital_app/widgets/anuncios_carousel.dart';
import 'package:uptmdigital_app/services/notification_service.dart';
import 'package:uptmdigital_app/widgets/notification_bell_button.dart';
 // For Clipboard
import 'package:uptmdigital_app/screens/horarios_screen.dart';
import 'package:uptmdigital_app/screens/inbox_screen.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:uptmdigital_app/widgets/menu_bottom_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  // Daree data
  Map<String, dynamic>? _dareeDocente;
  Map<String, dynamic>? _periodoActivo;

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
    String? loadedCedula;

    // 1. Cargar de caché primero
    final cached = await api.storage.read(key: 'cached_user_me');
    if (cached != null && mounted) {
      final cachedMap = jsonDecode(cached) as Map<String, dynamic>;
      loadedCedula = cachedMap['cedula'] as String?;
      setState(() {
        _professorData = cachedMap;
        _isLoading = false;
      });
      _loadDareeData(); // Start Daree loading early
    }

    // 2. Cargar de red para actualizar
    final data = await api.getUserMe();
    
    // Fallback: Si no tiene el perfil de profesor en /me, intentar recuperarlo
    if (mounted && data != null && data['idProfesor'] == null) {
      debugPrint("ProfessorDashboard: idProfesor null en /me, intentando fallback");
      await api.getCoordinadorMe();
    }

    if (mounted && data != null) {
      final newCedula = data['cedula'] as String?;
      setState(() {
        _professorData = data;
        _isLoading = false;
      });
      // Solo recargar Daree si no se había iniciado desde caché o cambió la cédula
      if (loadedCedula == null || loadedCedula != newCedula) {
        _loadDareeData();
      }
    } else if (mounted && _professorData == null) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDareeData() async {
    final api = ApiService();
    try {
      final cedula = _professorData?['cedula'] as String?;
      final futures = <Future<dynamic>>[
        api.getDareePeriodoActivo(),
        if (cedula != null && cedula.isNotEmpty)
          api.getDareeDocenteDetalle(cedula),
      ];

      final results = await Future.wait(futures);
      final periodo = results[0] as Map<String, dynamic>?;
      final docente = results.length > 1 ? results[1] as Map<String, dynamic>? : null;

      if (mounted) {
        setState(() {
          if (periodo != null) _periodoActivo = periodo;
          if (docente != null) _dareeDocente = docente;
        });
      }
    } catch (e) {
      debugPrint('Professor Daree load error: $e');
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
    final idProfesor = _professorData!['idProfesor'];
    if (idProfesor == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: ID de profesor no encontrado")));
      setState(() => _isLoading = false);
      return;
    }
    final fileName = "profile_prof_$idProfesor.jpg";

    final url = await SupabaseService().uploadImage(file, fileName);

    if (url != null) {
      final success = await ApiService().updateProfesor(idProfesor, {
        ..._professorData!,
        'fotoUrl': url
      });

      if (success) {
        _loadProfessorData();
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
        // Enviar a selección de materia primero para horario
        activePage = SubjectSelectionScreen(
          target: AcademicTarget.horarios, 
          professorId: _professorData!['idProfesor'],
          carrera: _professorData!['carrera'],
          semestre: {'idSemestre': 0, 'nombre': 'Mis Horarios'},
        );
        break;
      case 2:
        activePage = SubjectSelectionScreen(
          target: AcademicTarget.asistencias, 
          professorId: _professorData!['idProfesor'],
          carrera: _professorData!['carrera'],
          semestre: {'idSemestre': 0, 'nombre': 'Mis Asistencias'},
        );
        break;
      case 3:
        activePage = SubjectSelectionScreen(
          target: AcademicTarget.notas, 
          professorId: _professorData!['idProfesor'],
          carrera: _professorData!['carrera'],
          semestre: {'idSemestre': 0, 'nombre': 'Mis Calificaciones'},
        );
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
          const NotificationBellButton(),
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
            _buildNavItem(Icons.assignment_outlined, "Asistencia", 2),
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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                    backgroundImage: (_professorData!['fotoUrl'] != null && _professorData!['fotoUrl'].toString().isNotEmpty) 
                        ? NetworkImage(_professorData!['fotoUrl']) 
                        : null,
                    child: (_professorData!['fotoUrl'] == null || _professorData!['fotoUrl'].toString().isEmpty) 
                        ? Text(_professorData!['nombres'][0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondary))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary,
                      child: InkWell(
                        onTap: _pickProfileImage,
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
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
                    // Daree enrichment: profesión y especialidad
                    if (_dareeDocente?['data'] != null) ...[
                      if (_dareeDocente!['data']['profesion'] != null)
                        Text(
                          _dareeDocente!['data']['profesion'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      if (_dareeDocente!['data']['especialidad'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _dareeDocente!['data']['especialidad'],
                            style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
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

        // 2. Periodo Activo
        if (_periodoActivo != null)
          InstitutionalCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today, color: AppTheme.secondary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Periodo Activo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        _periodoActivo!['nombre'] ?? _periodoActivo!['codigo'] ?? 'Sin periodo',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _periodoActivo!['fase'] ?? '',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),

        // 3. Carga Académica (Daree)
        if (_dareeDocente != null && (_dareeDocente!['cargaAcademica'] as List<dynamic>?)?.isNotEmpty == true)
          InstitutionalCard(
            title: "Mi Carga Académica",
            child: Column(
              children: [
                // Summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCargaStat("Secciones", "${(_dareeDocente!['cargaAcademica'] as List).length}", AppTheme.primary),
                    _buildCargaStat(
                      "Estudiantes",
                      "${(_dareeDocente!['cargaAcademica'] as List).fold<int>(0, (sum, s) => sum + ((s['inscritos'] as int?) ?? 0))}",
                      AppTheme.secondary,
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Section list
                ...(_dareeDocente!['cargaAcademica'] as List<dynamic>).map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.class_, size: 20, color: AppTheme.secondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['nombreUc'] ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              "${s['trayecto'] ?? ''} • Sec. ${s['letraSeccion'] ?? ''} • ${s['aula'] ?? 'S/A'}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "${s['inscritos'] ?? 0}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                          ),
                          Icon(Icons.people, size: 14, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

        // 4. News
        InstitutionalCard(
          title: "Noticias Institucionales",
          padding: EdgeInsets.zero,
          child: const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: AnunciosCarousel(),
          ),
        ),
      ],
    );
  }

  Widget _buildCargaStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
