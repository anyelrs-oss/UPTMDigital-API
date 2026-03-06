import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/nota.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/nota_form_screen.dart';

class NotasScreen extends StatefulWidget {
  final int? professorId;
  const NotasScreen({super.key, this.professorId});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  late Future<List<Nota>> futureNotas;

  @override
  void initState() {
    super.initState();
    futureNotas = _loadNotas();
  }

  Future<List<Nota>> _loadNotas() async {
    try {
      final data = await ApiService().getNotas();
      var list = data.map<Nota>((json) => Nota.fromJson(json)).toList();
      if (widget.professorId != null) {
        list = list.where((n) => n.profesorId == widget.professorId).toList();
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notas")),
      body: FutureBuilder<List<Nota>>(
        future: futureNotas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar notas"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = snapshot.data![i];
                return Card(
                  child: ListTile(
                    title: Text("Nota: ${item.calificacion}"),
                    subtitle: Text("Estudiante ID: ${item.estudianteId} - Asignatura ID: ${item.asignaturaId}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.professorId != null) // Only show edit if viewing as Professor (filtered by professorId)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditNotaDialog(item);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ApiService().deleteNota(item.idNota);
                            setState(() {
                              futureNotas = _loadNotas();
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      // Keep existing detailed edit/view
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotaFormScreen(nota: item)),
                      );
                      if (result == true) {
                        setState(() {
                          futureNotas = _loadNotas();
                        });
                      }
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text("No hay notas"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotaFormScreen()),
          );
          if (result == true) {
            setState(() {
              futureNotas = _loadNotas();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  void _showEditNotaDialog(Nota nota) {
    final _calificacionController = TextEditingController(text: nota.calificacion?.toString() ?? "");
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Nota"),
        content: TextField(
          controller: _calificacionController,
          decoration: const InputDecoration(labelText: "Calificación"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = double.tryParse(_calificacionController.text);
              if (newValue == null) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valor inválido")));
                 return;
              }

              // Create updated map
              final updatedData = nota.toJson();
              updatedData['calificacion'] = newValue;
              
              // We need to ensure we don't send nulls for required fields or fields that confuse backend if they are present but unchanged 
              // (usually safer to just send what we have if backend accepts full object updates, or patch if patches)
              // Here we assume PUT replaces or updates.
              
              final success = await ApiService().updateNota(nota.idNota, updatedData);
              if (success) {
                 Navigator.pop(ctx);
                 setState(() {
                   futureNotas = _loadNotas();
                 });
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nota actualizada")));
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar nota")));
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
