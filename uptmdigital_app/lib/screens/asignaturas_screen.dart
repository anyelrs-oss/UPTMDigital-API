import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/asignatura_form_screen.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';
import 'package:uptmdigital_app/services/pdf_service.dart';
import 'package:uptmdigital_app/services/excel_service.dart';

class AsignaturasScreen extends StatefulWidget {
  final int? professorId;
  const AsignaturasScreen({super.key, this.professorId});

  @override
  State<AsignaturasScreen> createState() => _AsignaturasScreenState();
}

class _AsignaturasScreenState extends State<AsignaturasScreen> {
  late Future<List<Asignatura>> futureAsignaturas;

  @override
  void initState() {
    super.initState();
    futureAsignaturas = _loadAsignaturas();
  }

  Future<List<Asignatura>> _loadAsignaturas() async {
    try {
      final data = await ApiService().getAsignaturas();
      var list = data.map<Asignatura>((json) => Asignatura.fromJson(json)).toList();
      if (widget.professorId != null) {
        list = list.where((a) => a.profesorId == widget.professorId).toList();
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Asignaturas"),
      ),
      body: FutureBuilder<List<Asignatura>>(
        future: futureAsignaturas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar asignaturas"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final a = snapshot.data![i];
                return Card(
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AsignaturaFormScreen(asignatura: a),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          futureAsignaturas = _loadAsignaturas();
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: Text(
                              a.nombre.isNotEmpty ? a.nombre[0].toUpperCase() : "A",
                              style: const TextStyle(color: Colors.purple),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        a.codigo,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Sem: ${a.semestre} • UC: ${a.creditos}",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    asignaturaId: a.idAsignatura,
                                    asignaturaNombre: a.nombre,
                                    userName: "Profesor",
                                  ),
                                ),
                              );
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.download_for_offline, color: Colors.green),
                            onSelected: (value) async {
                                final students = await ApiService().getInscripcionesByAsignatura(a.idAsignatura);
                                if (students.isEmpty) {
                                  if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay estudiantes inscritos.")));
                                  }
                                  return;
                                }

                                if (value == 'pdf') {
                                    await PdfService().generateClassListPdf(a.nombre, students);
                                } else if (value == 'excel') {
                                    await ExcelService().generateClassListExcel(a.nombre, students);
                                }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'pdf',
                                child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('Lista en PDF')]),
                              ),
                              const PopupMenuItem<String>(
                                value: 'excel',
                                child: Row(children: [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 8), Text('Lista en Excel')]),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Eliminar Asignatura"),
                                  content: Text("¿Eliminar a ${a.nombre}?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final success = await ApiService().deleteAsignatura(a.idAsignatura);
                                if (success) {
                                  setState(() {
                                    futureAsignaturas = _loadAsignaturas();
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text("No hay asignaturas registradas"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AsignaturaFormScreen()),
          );
          if (result == true) {
            setState(() {
              futureAsignaturas = _loadAsignaturas();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
