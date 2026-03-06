import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/horario.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';

class HorariosScreen extends StatefulWidget {
  final bool isAdmin;
  final int? studentId; // If student, filter by their subjects (optional logic, for now show all enrolled)
  final int? professorId; // If professor, filter by their subjects

  const HorariosScreen({super.key, this.isAdmin = false, this.studentId, this.professorId});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  List<Asignatura> asignaturas = [];
  Map<int, List<Horario>> horariosMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // 1. Load Asignaturas relevant to the user
      final allAsignaturasData = await ApiService().getAsignaturas();
      var list = allAsignaturasData.map<Asignatura>((json) => Asignatura.fromJson(json)).toList();

      if (widget.professorId != null) {
        list = list.where((a) => a.profesorId == widget.professorId).toList();
      } 
      // For student, ideally we fetch enrolled subjects. For demo, we might show all or fetch enrollments.
      // Let's simplified: If student, show all (or implement filter later). For now, show all.
      
      asignaturas = list;

      // 2. Load Horarios for each Asignatura
      for (var asig in asignaturas) {
        final hData = await ApiService().getHorarios(asig.idAsignatura);
        horariosMap[asig.idAsignatura] = hData.map<Horario>((json) => Horario.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error loading schedules: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Horarios de Clases")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: asignaturas.length,
              itemBuilder: (ctx, i) {
                final asig = asignaturas[i];
                final horarios = horariosMap[asig.idAsignatura] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(asig.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${asig.codigo} - Semestre ${asig.semestre}"),
                    children: [
                      if (horarios.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text("No hay horarios asignados.")),
                      
                      ...horarios.map((h) => ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.blue),
                        title: Text("${h.dia}: ${h.horaInicio} - ${h.horaFin}"),
                        subtitle: Text("Aula: ${h.aula}"),
                        trailing: widget.isAdmin
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await ApiService().deleteHorario(h.idHorario);
                                  _loadData();
                                },
                              )
                            : null,
                      )),

                      if (widget.isAdmin)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Agregar Horario"),
                            onPressed: () => _showAddHorarioDialog(asig),
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddHorarioDialog(Asignatura asig) {
    final diaCtrl = TextEditingController();
    final inicioCtrl = TextEditingController();
    final finCtrl = TextEditingController();
    final aulaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nuevo Horario para ${asig.nombre}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: diaCtrl, decoration: const InputDecoration(labelText: "Día (Ej: Lunes)")),
            TextField(controller: inicioCtrl, decoration: const InputDecoration(labelText: "Hora Inicio (Ej: 08:00)")),
            TextField(controller: finCtrl, decoration: const InputDecoration(labelText: "Hora Fin (Ej: 10:00)")),
            TextField(controller: aulaCtrl, decoration: const InputDecoration(labelText: "Aula")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (diaCtrl.text.isEmpty || inicioCtrl.text.isEmpty) return;
              
              final result = await ApiService().createHorario({
                "asignaturaId": asig.idAsignatura,
                "dia": diaCtrl.text,
                "horaInicio": inicioCtrl.text,
                "horaFin": finCtrl.text,
                "aula": aulaCtrl.text
              });

              if (result && mounted) {
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }
}
