import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:file_picker/file_picker.dart';

class PlanEvaluacionScreen extends StatefulWidget {
  final int asignaturaId;
  final String asignaturaNombre;

  const PlanEvaluacionScreen({
    super.key,
    required this.asignaturaId,
    required this.asignaturaNombre,
  });

  @override
  State<PlanEvaluacionScreen> createState() => _PlanEvaluacionScreenState();
}

class _PlanEvaluacionScreenState extends State<PlanEvaluacionScreen> {
  final List<Map<String, dynamic>> _evaluaciones = [];
  bool _includeAttendance = false;
  double _attendancePoints = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addInitialRow();
  }

  void _addInitialRow() {
    _evaluaciones.add({
      "nombre": TextEditingController(),
      "ponderacion": TextEditingController(),
      "fecha": DateTime.now().add(const Duration(days: 15)),
    });
  }

  double get _totalPonderacion {
    double total = _includeAttendance ? _attendancePoints : 0;
    for (var e in _evaluaciones) {
      total += double.tryParse(e['ponderacion'].text) ?? 0;
    }
    return total;
  }

  Future<void> _guardarPlan() async {
    if (_totalPonderacion != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("El total debe ser 100%. Actual: $_totalPonderacion%"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final api = ApiService();

    try {
      if (_includeAttendance) {
        await api.createEvaluacion({
          "asignaturaId": widget.asignaturaId,
          "nombre": "Asistencia",
          "ponderacion": _attendancePoints,
          "fechaEvaluacion": DateTime.now().toIso8601String(),
        });
      }

      for (var e in _evaluaciones) {
        await api.createEvaluacion({
          "asignaturaId": widget.asignaturaId,
          "nombre": e['nombre'].text,
          "ponderacion": double.parse(e['ponderacion'].text),
          "fechaEvaluacion": (e['fecha'] as DateTime).toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan de evaluación guardado")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar el plan")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importFromPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);
    final api = ApiService();
    final response = await api.extractEvaluationPlan(result.files.single.path!);
    setState(() => _isLoading = false);

    if (response != null && response['data'] != null) {
      final List extracted = response['data'];
      if (extracted.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se detectaron tablas claras. Intente un formato más legible.")));
        return;
      }

      setState(() {
        _evaluaciones.clear();
        for (var item in extracted) {
          final nombreCtrl = TextEditingController(text: item['nombre']);
          final pondCtrl = TextEditingController(text: item['ponderacion'].toString());

          // Parse date dd/mm/yyyy
          DateTime date;
          try {
            final parts = item['fechaStr'].split('/');
            date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          } catch (_) {
            date = DateTime.now();
          }

          _evaluaciones.add({
            "nombre": nombreCtrl,
            "ponderacion": pondCtrl,
            "fecha": date,
          });
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Se extrajeron ${extracted.length} evaluaciones. Por favor verifique los datos.")));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al procesar el archivo."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Plan: ${widget.asignaturaNombre}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InstitutionalCard(
              title: "Parámetros Generales",
              child: CheckboxListTile(
                title: const Text("Incluir Asistencia como nota"),
                subtitle: const Text("Se restará del total de evaluaciones"),
                value: _includeAttendance,
                onChanged: (val) => setState(() {
                  _includeAttendance = val!;
                  if (_includeAttendance && _attendancePoints == 0) _attendancePoints = 10;
                }),
              ),
            ),
            if (_includeAttendance)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text("Puntos por Asistencia:"),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Slider(
                        value: _attendancePoints,
                        min: 0, max: 30, divisions: 6,
                        label: "${_attendancePoints.toInt()}%",
                        onChanged: (val) => setState(() => _attendancePoints = val),
                      ),
                    ),
                    Text("${_attendancePoints.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _evaluaciones.length,
              itemBuilder: (ctx, i) => _buildEvalRow(i),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _addInitialRow()),
                  icon: const Icon(Icons.add),
                  label: const Text("Añadir Fila"),
                ),
                TextButton.icon(
                  onPressed: _importFromPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Importar PDF"),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ),
            const Divider(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _totalPonderacion == 100 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL PONDERACIÓN:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "$_totalPonderacion / 100 %",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _totalPonderacion == 100 ? Colors.green : Colors.red
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarPlan,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator() : const Text("CARGAR PLAN COMPLETO"),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalRow(int index) {
    final e = _evaluaciones[index];
    return InstitutionalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: TextField(controller: e['nombre'], decoration: const InputDecoration(labelText: "Evaluación (Ej: Taller 1)"))),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: TextField(controller: e['ponderacion'], decoration: const InputDecoration(labelText: "%"), keyboardType: TextInputType.number)),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _evaluaciones.removeAt(index))),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: e['fecha'],
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => e['fecha'] = picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text("Fecha programada: ${(e['fecha'] as DateTime).day}/${(e['fecha'] as DateTime).month}"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
