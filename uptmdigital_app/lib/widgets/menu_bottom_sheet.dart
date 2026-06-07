import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/carnet_screen.dart';
import 'package:uptmdigital_app/screens/qr_scan_screen.dart';
import 'package:uptmdigital_app/screens/horarios_screen.dart';
import 'package:uptmdigital_app/screens/constancias_screen.dart';
import 'package:uptmdigital_app/screens/generate_qr_screen.dart';
import 'package:uptmdigital_app/screens/asistencias_screen.dart';
import 'package:uptmdigital_app/screens/notas_screen.dart';
import 'package:uptmdigital_app/screens/my_grades_screen.dart';
import 'package:uptmdigital_app/screens/noticias_list_screen.dart';
import 'package:uptmdigital_app/screens/inbox_screen.dart';
import 'package:uptmdigital_app/screens/security_qr_screen.dart';
import 'package:uptmdigital_app/screens/classroom_opening_screen.dart';
import 'package:uptmdigital_app/screens/reporte_asistencia_docente_screen.dart';
import 'package:uptmdigital_app/screens/anuncios_admin_screen.dart';
import 'package:uptmdigital_app/screens/auditoria_main_screen.dart';

class MenuBottomSheet extends StatelessWidget {
  final String role; // 'admin', 'student', 'professor', 'security'
  final Map<String, dynamic>? userData; // Passed from dashboard to allow navigation with data

  const MenuBottomSheet({super.key, required this.role, this.userData});

  @override
  Widget build(BuildContext context) {
    final sections = _getMenuSectionsForRole(context, role);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                  child: const Icon(Icons.apps, color: AppTheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getMenuTitle(role),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Scrollable Sections
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 30),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Text(
                        section['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 items per row like Mercantil/Bank apps
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0, 
                      ),
                      itemCount: (section['items'] as List).length,
                      itemBuilder: (context, itemIndex) {
                        final item = (section['items'] as List)[itemIndex];
                        return _buildMenuItem(
                          context, 
                          item['icon'] as IconData, 
                          item['label'] as String, 
                          item['onTap'] as VoidCallback
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getMenuTitle(String role) {
    switch (role.toLowerCase()) {
      case 'student': return "Menú de Estudiante";
      case 'professor': return "Menú de Profesor";
      case 'admin': return "Menú de Administrador";
      case 'security': return "Menú de Seguridad";
      case 'secretaria':
      case 'secretary': return "Menú de Secretaría";
      case 'coordinador':
      case 'coordinator': return "Menú de Coordinación";
      case 'auditor': return "Menú de Auditoría";
      default: return "Menú de Usuario";
    }
  }

  List<Map<String, dynamic>> _getMenuSectionsForRole(BuildContext context, String role) {
    void nav(Widget screen) {
      Navigator.pop(context); // Close sheet before navigating
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
    void notImpl() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente")));
    
    // Safety check for userData
    bool hasData = userData != null;

    switch (role.toLowerCase()) {
      case 'student':
        return [
          {
            'title': 'ACADÉMICO',
            'items': [
              {'icon': Icons.grade, 'label': 'Notas', 'onTap': () => nav(const MyGradesScreen())},
              {'icon': Icons.description, 'label': 'Constancias', 'onTap': () {
                 if (hasData) {
                   nav(ConstanciasScreen(studentId: userData!['idEstudiante']));
                 } else {
                   notImpl();
                 }
              }},
              {'icon': Icons.calendar_month, 'label': 'Horario', 'onTap': () {
                 if (hasData) {
                   nav(HorariosScreen(studentId: userData!['idEstudiante']));
                 } else {
                   notImpl();
                 }
              }},
            ]
          },
          {
            'title': 'COMUNICACIÓN',
            'items': [
              {'icon': Icons.chat_bubble_outline, 'label': 'Chats', 'onTap': () => nav(const InboxScreen())},
              {'icon': Icons.newspaper, 'label': 'Noticias', 'onTap': () => nav(const NoticiasListScreen())},
            ]
          },
          {
            'title': 'SEGURIDAD & OTROS',
            'items': [
              {'icon': Icons.badge_outlined, 'label': 'Carnet Digital', 'onTap': () {
                 if (hasData) {
                   nav(CarnetScreen(userData: {...userData!, 'rol': 'Estudiante'}));
                 } else {
                   notImpl();
                 }
              }},
              {'icon': Icons.qr_code_scanner, 'label': 'Escanear QR', 'onTap': () {
                 if (hasData && userData!['idEstudiante'] != null) {
                    nav(QRScanScreen(studentId: userData!['idEstudiante']));
                 } else {
                    notImpl();
                 }
              }}, 
            ]
          }
        ];
      case 'professor':
        return [
          {
            'title': 'GESTIÓN DE CLASES',
            'items': [
              {'icon': Icons.qr_code_2, 'label': 'Generar QR', 'onTap': () {
                 if (hasData) {
                   nav(GenerateQRScreen(professorId: userData!['idProfesor']));
                 } else {
                   notImpl();
                 }
              }},
              {'icon': Icons.assignment_turned_in, 'label': 'Evaluar', 'onTap': () {
                 if (hasData) {
                   nav(NotasScreen(professorId: userData!['idProfesor']));
                 } else {
                   notImpl();
                 }
              }},
              {'icon': Icons.list_alt, 'label': 'Asistencia', 'onTap': () {
                 if (hasData) {
                   nav(AsistenciasScreen(professorId: userData!['idProfesor']));
                 } else {
                   notImpl();
                 }
              }},
              {'icon': Icons.calendar_today, 'label': 'Horario', 'onTap': () {
                 if (hasData) {
                   nav(HorariosScreen(professorId: userData!['idProfesor']));
                 } else {
                   notImpl();
                 }
              }},
            ]
          },
          {
             'title': 'COMUNICACIÓN',
             'items': [
               {'icon': Icons.chat, 'label': 'Chats', 'onTap': notImpl},
               {'icon': Icons.campaign, 'label': 'Anuncios', 'onTap': notImpl},
             ]
          },
          {
            'title': 'IDENTIFICACIÓN',
            'items': [
              {'icon': Icons.badge_outlined, 'label': 'Carnet Digital', 'onTap': () {
                 if (hasData) {
                   nav(CarnetScreen(userData: {...userData!, 'rol': 'Profesor'}));
                 } else {
                   notImpl();
                 }
              }},
            ]
          }
        ];
      case 'admin':
        return [
          {
            'title': 'ADMINISTRACIÓN',
            'items': [
               {'icon': Icons.people, 'label': 'Usuarios', 'onTap': notImpl},
               {'icon': Icons.settings_system_daydream, 'label': 'Sistema', 'onTap': notImpl},
            ]
          },
          {
            'title': 'REPORTES',
             'items': [
               {'icon': Icons.bar_chart, 'label': 'Estadísticas', 'onTap': notImpl},
               {'icon': Icons.file_download, 'label': 'Exportar', 'onTap': notImpl},
             ]
          },
          {
            'title': 'IDENTIFICACIÓN',
            'items': [
              {'icon': Icons.badge_outlined, 'label': 'Carnet Digital', 'onTap': () {
                 if (hasData) {
                   nav(CarnetScreen(userData: {...userData!, 'rol': 'Admin'}));
                 } else {
                   notImpl();
                 }
              }},
            ]
          }
        ];
      case 'security':
        return [
           {
            'title': 'CONTROL DE ACCESO',
            'items': [
               {'icon': Icons.qr_code_scanner, 'label': 'Escanear', 'onTap': () => nav(const SecurityQRScreen())},
               {'icon': Icons.history, 'label': 'Historial', 'onTap': () {
                  notImpl();
               }},
               {'icon': Icons.lock_open, 'label': 'Apertura Aulas', 'onTap': () => nav(const ClassroomOpeningScreen())},
            ]
           },
           {
             'title': 'SISTEMA',
             'items': [
               {'icon': Icons.report_problem, 'label': 'Reportes', 'onTap': notImpl},
               {'icon': Icons.info_outline, 'label': 'Estado API', 'onTap': () async {
                  final ok = await ApiService.instance.getHealth();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? "Servidor Conectado" : "Servidor No Disponible"),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ));
                  }
               }},
             ]
           },
           {
            'title': 'IDENTIFICACIÓN',
            'items': [
              {'icon': Icons.badge_outlined, 'label': 'Carnet Digital', 'onTap': () {
                 if (hasData) {
                   nav(CarnetScreen(userData: {...userData!, 'rol': 'Seguridad'}));
                 } else {
                   notImpl();
                 }
              }},
            ]
          }
        ];
      case 'secretaria':
      case 'secretary':
        return [
          {
            'title': 'GESTIÓN',
            'items': [
              {'icon': Icons.point_of_sale, 'label': 'Aranceles', 'onTap': () {
                // If it's already in the dashboard, maybe just close the sheet
                Navigator.pop(context);
              }},
              {'icon': Icons.description, 'label': 'Reportes', 'onTap': () {
                nav(const ReporteAsistenciaDocenteScreen());
              }},
            ]
          },
          {
            'title': 'IDENTIFICACIÓN',
            'items': [
              {'icon': Icons.badge_outlined, 'label': 'Carnet Digital', 'onTap': () {
                 if (hasData) {
                   nav(CarnetScreen(userData: {...userData!, 'rol': 'Secretaria'}));
                 } else {
                   notImpl();
                 }
              }},
            ]
          }
        ];
      case 'coordinador':
      case 'coordinator':
        return [
          {
            'title': 'COORDINACIÓN',
            'items': [
               {'icon': Icons.campaign, 'label': 'Anuncios', 'onTap': () => nav(const AnunciosAdminScreen())},
               {'icon': Icons.chat, 'label': 'Chats', 'onTap': () => nav(const InboxScreen())},
            ]
          },
          {
            'title': 'IDENTIFICACIÓN',
            'items': [
              {'icon': Icons.badge_outlined, 'label': 'Carnet Digital', 'onTap': () {
                 if (hasData) {
                   nav(CarnetScreen(userData: {...userData!, 'rol': 'Coordinador'}));
                 } else {
                   notImpl();
                 }
              }},
            ]
          }
        ];
      case 'auditor':
        return [
          {
            'title': 'AUDITORÍA',
            'items': [
              {'icon': Icons.history, 'label': 'Logs', 'onTap': () => nav(const AuditoriaMainScreen())},
            ]
          },
          {
            'title': 'IDENTIFICACIÓN',
            'items': [
              {'icon': Icons.badge_outlined, 'label': 'Carnet Digital', 'onTap': () {
                 if (hasData) {
                   nav(CarnetScreen(userData: {...userData!, 'rol': 'Auditor'}));
                 } else {
                   notImpl();
                 }
              }},
            ]
          }
        ];
      default:
        return [];
    }
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.02),
               blurRadius: 5,
               offset: const Offset(0, 2),
             )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.secondary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
