import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/profesor.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/professor_form_screen.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  late Future<List<Profesor>> futureProfesores;

  @override
  void initState() {
    super.initState();
    futureProfesores = _loadProfesores();
  }

  Future<List<Profesor>> _loadProfesores() async {
    try {
      final data = await ApiService().getProfesores();
      return data.map<Profesor>((json) => Profesor.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Profesores"),
      ),
      body: FutureBuilder<List<Profesor>>(
        future: futureProfesores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar profesores"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final p = snapshot.data![i];
                return Card(
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfessorFormScreen(profesor: p),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          futureProfesores = _loadProfesores();
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.secondary.withOpacity(0.1),
                            child: Text(
                              p.nombres.isNotEmpty ? p.nombres[0].toUpperCase() : "P",
                              style: const TextStyle(color: AppTheme.secondary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${p.nombres} ${p.apellidos}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  p.departamento,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Eliminar Profesor"),
                                  content: Text("¿Eliminar a ${p.nombres}?"),
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
                                final success = await ApiService().deleteProfesor(p.idProfesor);
                                if (success) {
                                  setState(() {
                                    futureProfesores = _loadProfesores();
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
          return const Center(child: Text("No hay profesores registrados"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfessorFormScreen()),
          );
          if (result == true) {
            setState(() {
              futureProfesores = _loadProfesores();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
