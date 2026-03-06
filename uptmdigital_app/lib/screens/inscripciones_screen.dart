import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/inscripcion.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/inscripcion_form_screen.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';

class InscripcionesScreen extends StatefulWidget {
  final int? studentId;
  const InscripcionesScreen({super.key, this.studentId});

  @override
  State<InscripcionesScreen> createState() => _InscripcionesScreenState();
}

class _InscripcionesScreenState extends State<InscripcionesScreen> {
  late Future<List<Inscripcion>> futureInscripciones;

  @override
  void initState() {
    super.initState();
    futureInscripciones = _loadInscripciones();
  }

  Future<List<Inscripcion>> _loadInscripciones() async {
    try {
      final data = await ApiService().getInscripciones();
      var list = data.map<Inscripcion>((json) => Inscripcion.fromJson(json)).toList();
      if (widget.studentId != null) {
        list = list.where((i) => i.estudianteId == widget.studentId).toList();
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscripciones")),
      body: FutureBuilder<List<Inscripcion>>(
        future: futureInscripciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar inscripciones"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = snapshot.data![i];
                return Card(
                  child: ListTile(
                    title: Text("Inscripción #${item.idInscripcion}"),
                    subtitle: Text("Asignatura ID: ${item.asignaturaId} - ${item.estado}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.blue),
                          onPressed: () {
                             // We don't have the subject name here easily without fetching all subjects via ID.
                             // For now, we will just show "Chat de Asignatura" in title.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    asignaturaId: item.asignaturaId,
                                    asignaturaNombre: "Asignatura ${item.asignaturaId}",
                                    userName: "Estudiante", // Simplified
                                  ),
                                ),
                              );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ApiService().deleteInscripcion(item.idInscripcion);
                            setState(() {
                              futureInscripciones = _loadInscripciones();
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InscripcionFormScreen(inscripcion: item)),
                      );
                      if (result == true) {
                        setState(() {
                          futureInscripciones = _loadInscripciones();
                        });
                      }
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text("No hay inscripciones"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InscripcionFormScreen()),
          );
          if (result == true) {
            setState(() {
              futureInscripciones = _loadInscripciones();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
