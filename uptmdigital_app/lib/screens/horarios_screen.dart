
import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';
import 'package:uptmdigital_app/screens/plan_evaluacion_screen.dart';
import 'package:uptmdigital_app/screens/my_grades_screen.dart';
import 'package:uptmdigital_app/theme.dart';

import 'package:uptmdigital_app/screens/asistencias_screen.dart';
import 'package:uptmdigital_app/screens/evaluar_screen.dart';
import 'package:uptmdigital_app/screens/notas_screen.dart';

class HorariosScreen extends StatefulWidget {
  final bool isAdmin;
  final int? studentId;
  final int? professorId;
  final int? asignaturaId;
  final String? asignaturaNombre;

  const HorariosScreen({
    super.key,
    this.isAdmin = false,
    this.studentId,
    this.professorId,
    this.asignaturaId,
    this.asignaturaNombre,
  });

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  List<Asignatura> _asignaturas = [];
  final Map<int, List<dynamic>> _horariosMap = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _normalize(String str) {
    return str
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    try {
      if (widget.asignaturaId != null) {
        // Carga rápida: Solo una materia
        final h = await api.getHorarios(widget.asignaturaId!);
        _horariosMap[widget.asignaturaId!] = h;
        // Creamos una asignatura ficticia para la UI si no la tenemos completa
        _asignaturas = [Asignatura(
          idAsignatura: widget.asignaturaId!,
          nombre: widget.asignaturaNombre ?? "Materia Seleccionada",
          codigo: "",
          semestreNombre: "",
          creditos: 0,
          departamento: "",
        )];
      } else {
        // Carga completa con filtrado inteligente
        var list = <Asignatura>[];
        final userRole = await api.storage.read(key: 'user_role');

        if (userRole == 'Estudiante') {
          // 1. Obtener inscripciones del estudiante
          final inscripciones = await api.getStudentInscripcionesMe();

          if (inscripciones.isNotEmpty) {
            // Si el estudiante tiene inscripciones, mostramos solo las materias en las que está inscrito
            final enrolledIds = inscripciones
                .map((ins) => ins['asignaturaId'] as int?)
                .where((id) => id != null)
                .cast<int>()
                .toSet();

            final all = await api.getAsignaturas();
            list = all
                .map<Asignatura>((json) => Asignatura.fromJson(json))
                .where((a) => enrolledIds.contains(a.idAsignatura))
                .toList();
          } else {
            // Si no tiene inscripciones, mostramos las materias de su carrera (departamento)
            var carreraNombre = await api.storage.read(key: 'carrera_nombre');
            final carreraIdStr = await api.storage.read(key: 'carrera_id');
            final int? carreraId = carreraIdStr != null ? int.tryParse(carreraIdStr) : null;

            if (carreraNombre == null || carreraNombre.isEmpty) {
              final me = await api.getUserMe();
              if (me != null && me['carrera'] != null && me['carrera']['nombre'] != null) {
                carreraNombre = me['carrera']['nombre'].toString();
              }
            }

            final all = await api.getAsignaturas();
            final mapped = all.map<Asignatura>((json) => Asignatura.fromJson(json)).toList();

            if (carreraId != null || (carreraNombre != null && carreraNombre.isNotEmpty)) {
              final normCarrera = carreraNombre != null ? _normalize(carreraNombre) : '';
              list = mapped.where((a) {
                if (carreraId != null && a.carreraId == carreraId) {
                  return true;
                }
                if (normCarrera.isNotEmpty && _normalize(a.departamento) == normCarrera) {
                  return true;
                }
                return false;
              }).toList();
            } else {
              list = []; // Si no hay carrera ni inscripciones, no mostramos nada
            }
          }
        } else {
          // Para otros roles (Coordinador, Profesor, Administrador)
          final all = await api.getAsignaturas();
          var temp = all.map<Asignatura>((json) => Asignatura.fromJson(json)).toList();

          if (widget.professorId != null) {
            temp = temp.where((a) => a.profesorId == widget.professorId).toList();
          }
          list = temp;
        }

        _asignaturas = list;
        for (var a in _asignaturas) {
          final h = await api.getHorarios(a.idAsignatura);
          _horariosMap[a.idAsignatura] = h;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _asignaturas.where((a) => a.nombre.toLowerCase().contains(_searchQuery)).toList();
    final String title = widget.asignaturaNombre ?? "Horarios Académicos";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          if (widget.asignaturaId == null) // Solo mostrar búsqueda si no es jerárquico
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar materia...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                  ? const Center(child: Text("No hay horarios registrados"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildMateriaCard(filtered[i]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriaCard(Asignatura a) {
    final list = _horariosMap[a.idAsignatura] ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(a.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            subtitle: Text("${a.codigo} • Semestre ${a.semestreNombre}", style: const TextStyle(fontSize: 12)),
            children: [
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No hay horarios asignados", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ...list.map((h) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time_filled, size: 24, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${h['dia']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${h['horaInicio']} - ${h['horaFin']}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Aula: ${h['aula']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (widget.isAdmin)
                          TextButton.icon(
                            onPressed: () => _showEditAulaDialog(h),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text("Editar", style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                          ),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
          if (widget.studentId != null || widget.professorId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.studentId != null 
                  ? [
                    _buildQuickAction(Icons.chat_bubble_outline, "Chat", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                        asignaturaId: a.idAsignatura,
                        title: a.nombre,
                        userName: "Estudiante",
                      )));
                    }),
                    _buildQuickAction(Icons.assignment_outlined, "Plan", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PlanEvaluacionScreen(
                        asignaturaId: a.idAsignatura,
                        asignaturaNombre: a.nombre,
                      )));
                    }),
                    _buildQuickAction(Icons.grade_outlined, "Notas", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyGradesScreen()));
                    }),
                  ]
                  : [
                    _buildQuickAction(Icons.chat_bubble_outline, "Chat", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                        asignaturaId: a.idAsignatura,
                        title: a.nombre,
                        userName: "Profesor",
                      )));
                    }),
                    _buildQuickAction(Icons.assignment_outlined, "Planificación", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PlanEvaluacionScreen(
                        asignaturaId: a.idAsignatura,
                        asignaturaNombre: a.nombre,
                      )));
                    }),
                    _buildQuickAction(Icons.grade_outlined, "Notas", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NotasScreen(
                        asignaturaId: a.idAsignatura, 
                        asignaturaNombre: a.nombre
                      )));
                    }),
                  ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0D1B2A)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: const Color(0xFF0D1B2A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showEditAulaDialog(dynamic h) {
    final aulaCtrl = TextEditingController(text: h['aula']);
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cambiar Aula"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: aulaCtrl, decoration: const InputDecoration(labelText: "Nueva Aula")),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Justificación"), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () { if (mounted) Navigator.pop(ctx); }, child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (aulaCtrl.text.isNotEmpty && reasonCtrl.text.isNotEmpty) {
                // Guardar motivo para auditoría
                await ApiService().storage.write(key: 'pending_delete_reason', value: "CAMBIO AULA: ${reasonCtrl.text}");

                final success = await ApiService().createHorario({
                  ...h,
                  "aula": aulaCtrl.text
                });
                if (success) {
                  if (mounted) Navigator.pop(ctx);
                  _loadData();
                }
              }
            },
            child: const Text("Actualizar"),
          )
        ],
      ),
    );
  }
}