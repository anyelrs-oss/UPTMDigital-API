import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/constancia.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/services/pdf_service.dart';
import 'package:uptmdigital_app/screens/constancia_form_screen.dart';

class ConstanciasScreen extends StatefulWidget {
  final int? studentId;
  const ConstanciasScreen({super.key, this.studentId});

  @override
  State<ConstanciasScreen> createState() => _ConstanciasScreenState();
}

class _ConstanciasScreenState extends State<ConstanciasScreen> {
  late Future<List<Constancia>> futureConstancias;

  @override
  void initState() {
    super.initState();
    futureConstancias = _loadConstancias();
  }

  Future<List<Constancia>> _loadConstancias() async {
    try {
      final data = await ApiService().getConstancias();
      var list = data.map<Constancia>((json) => Constancia.fromJson(json)).toList();
      if (widget.studentId != null) {
        list = list.where((c) => c.estudianteId == widget.studentId).toList();
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Constancias")),
      body: FutureBuilder<List<Constancia>>(
        future: futureConstancias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar constancias"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = snapshot.data![i];
                return Card(
                  child: ListTile(
                    title: Text(item.tipoConstancia),
                    subtitle: Text("Estudiante: ${item.estudianteId} - Estado: ${item.estado}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                          onPressed: () async {
                            // TODO: Fetch student details properly. Using placeholder for now if filtered or just generic.
                            // In a real app we might want to fetch the student name if not available in Current User context,
                            // but here we are likely the student (if widget.studentId is set) or admin.
                            // Let's assume we are the student or pass a generic name.
                            await PdfService().generateAndPrintConstancia(item, "Estudiante (ID ${item.estudianteId})", "N/A");
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ApiService().deleteConstancia(item.idConstancia);
                            setState(() {
                              futureConstancias = _loadConstancias();
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ConstanciaFormScreen(constancia: item)),
                      );
                      if (result == true) {
                        setState(() {
                          futureConstancias = _loadConstancias();
                        });
                      }
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text("No hay constancias"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConstanciaFormScreen()),
          );
          if (result == true) {
            setState(() {
              futureConstancias = _loadConstancias();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
