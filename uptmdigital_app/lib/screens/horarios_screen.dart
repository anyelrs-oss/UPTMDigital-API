
import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';
import 'package:uptmdigital_app/screens/plan_evaluacion_screen.dart';
import 'package:uptmdigital_app/screens/my_grades_screen.dart';

import 'package:uptmdigital_app/screens/asistencias_screen.dart';
import 'package:uptmdigital_app/screens/evaluar_screen.dart';

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
        // Carga completa (antigua, lenta)
        final all = await api.getAsignaturas();
        var list = all.map<Asignatura>((json) => Asignatura.fromJson(json)).toList();

        if (widget.professorId != null) {
          list = list.where((a) => a.profesorId == widget.professorId).toList();
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
            title: Text(a.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${a.codigo} • Semestre ${a.semestreNombre}"),
            children: list.map((h) => ListTile(
              leading: Icon(Icons.access_time, size: 20, color: const Color(0xFFC9A84C)),
              title: Text("${h['dia']}: ${h['horaInicio']} - ${h['horaFin']}"),
              subtitle: Text("Aula: ${h['aula']}"),
              trailing: widget.isAdmin
                  ? IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showEditAulaDialog(h))
                  : null,
            )).toList(),
          ),
          if (widget.studentId != null || widget.professorId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    _buildQuickAction(Icons.list_alt, "Asistencia", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AsistenciasScreen(
                        asignaturaId: a.idAsignatura,
                        asignaturaNombre: a.nombre,
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