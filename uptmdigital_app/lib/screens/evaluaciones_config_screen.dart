import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class EvaluacionesConfigScreen extends StatefulWidget {
  final int asignaturaId;
  final String asignaturaNombre;

  const EvaluacionesConfigScreen({
    super.key,
    required this.asignaturaId,
    required this.asignaturaNombre,
  });

  @override
  State<EvaluacionesConfigScreen> createState() => _EvaluacionesConfigScreenState();
}

class _EvaluacionesConfigScreenState extends State<EvaluacionesConfigScreen> {
  List<dynamic> _evaluaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluaciones();
  }

  Future<void> _loadEvaluaciones() async {
    final data = await ApiService().getEvaluaciones(widget.asignaturaId);
    if (mounted) {
      setState(() {
        _evaluaciones = data;
        _isLoading = false;
      });
    }
  }

  void _showAddDialog() {
    final nombreCtrl = TextEditingController();
    final pondCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nueva Evaluación"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre (Ej: Examen 1)")),
              TextField(controller: pondCtrl, decoration: const InputDecoration(labelText: "Ponderación %"), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Fecha:"),
                subtitle: Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  "asignaturaId": widget.asignaturaId,
                  "nombre": nombreCtrl.text,
                  "ponderacion": double.tryParse(pondCtrl.text) ?? 0,
                  "fechaEvaluacion": selectedDate.toIso8601String(),
                };
                final success = await ApiService().createEvaluacion(data);
                if (success) {
                  Navigator.pop(ctx);
                  _loadEvaluaciones();
                }
              },
              child: const Text("Crear"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Plan: ${widget.asignaturaNombre}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Configura las evaluaciones y sus fechas para que los estudiantes puedan verlas en sus dashboards.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ..._evaluaciones.map((e) => _buildEvalItem(e)),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text("Añadir Evaluación"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEvalItem(dynamic e) {
    final fecha = DateTime.parse(e['fechaEvaluacion']);
    return InstitutionalCard(
      child: ListTile(
        title: Text(e['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Fecha: ${fecha.day}/${fecha.month}/${fecha.year}"),
        trailing: Text("${e['ponderacion']}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
      ),
    );
  }
}