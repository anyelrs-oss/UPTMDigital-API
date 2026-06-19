import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:file_picker/file_picker.dart';

class PlanEvaluacionScreen extends StatefulWidget {
  final int asignaturaId;
  final String asignaturaNombre;
  final bool isReadOnly;

  const PlanEvaluacionScreen({
    super.key,
    required this.asignaturaId,
    required this.asignaturaNombre,
    this.isReadOnly = false,
  });

  @override
  State<PlanEvaluacionScreen> createState() => _PlanEvaluacionScreenState();
}

class _PlanEvaluacionScreenState extends State<PlanEvaluacionScreen> {
  final List<Map<String, dynamic>> _evaluaciones = [];
  bool _includeAttendance = false;
  double _attendancePoints = 0;
  bool _isLoading = false;
  bool _isConfirmed = false;

  bool get _effectiveReadOnly => widget.isReadOnly || _isConfirmed;

  @override
  void initState() {
    super.initState();
    _loadExistingPlan();
  }

  Future<void> _loadExistingPlan() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      
      final confirmado = await api.getGlobalSetting("Confirmado_Asignatura_${widget.asignaturaId}");
      if (confirmado == "true") {
        _isConfirmed = true;
      }

      final evaluaciones = await api.getEvaluaciones(widget.asignaturaId);
      
      if (mounted) {
        if (evaluaciones.isNotEmpty) {
          _evaluaciones.clear();
          for (var item in evaluaciones) {
            if (item['nombre'].toString().toLowerCase() == 'asistencia') {
              setState(() {
                _includeAttendance = true;
                _attendancePoints = (item['ponderacion'] as num).toDouble();
              });
              continue;
            }
            
            _evaluaciones.add({
              "idEvaluacion": item['idEvaluacion'],
              "nombre": TextEditingController(text: item['nombre']),
              "ponderacion": TextEditingController(text: item['ponderacion'].toString()),
              "fecha": DateTime.tryParse(item['fechaEvaluacion'] ?? '') ?? DateTime.now(),
            });
          }
          if (_evaluaciones.isEmpty && !_includeAttendance) _addInitialRow();
        } else {
          _addInitialRow();
        }
      }
    } catch (e) {
      debugPrint("Error loading existing plan: $e");
      if (mounted) _addInitialRow();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_effectiveReadOnly) return;

    if (_totalPonderacion != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("El total debe ser 100%. Actual: $_totalPonderacion%"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final api = ApiService();
    try {
      final List<Map<String, dynamic>> payload = [];

      if (_includeAttendance) {
        payload.add({
          "asignaturaId": widget.asignaturaId,
          "nombre": "Asistencia",
          "ponderacion": _attendancePoints,
          "fechaEvaluacion": DateTime.now().toUtc().toIso8601String(),
          "activo": true,
        });
      }

      for (var e in _evaluaciones) {
        payload.add({
          "asignaturaId": widget.asignaturaId,
          "nombre": e['nombre'].text,
          "ponderacion": double.parse(e['ponderacion'].text),
          "fechaEvaluacion": (e['fecha'] as DateTime).toUtc().toIso8601String(),
          "activo": true,
        });
      }

      final res = await api.savePlanEvaluacion(widget.asignaturaId, payload);

      if (!res['success']) {
        throw Exception(res['message']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan de evaluación guardado")));
        Navigator.pop(context);
      }
    } catch (e) {
      final msg = e.toString().replaceFirst("Exception: ", "");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $msg"), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importFromPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);
    final api = ApiService();
    final res = await api.extractEvaluationPlan(result.files.single.path!);
    setState(() => _isLoading = false);

    if (res != null && res['data'] != null) {
      final List data = res['data'];
      setState(() {
        _evaluaciones.clear();
        for (var item in data) {
          _evaluaciones.add({
            "nombre": TextEditingController(text: item['nombre']),
            "ponderacion": TextEditingController(text: item['ponderacion'].toString()),
            "fecha": DateTime.tryParse(item['fechaStr'] ?? '') ?? DateTime.now(),
          });
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan extraído del PDF.")));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo extraer el plan."), backgroundColor: Colors.red));
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
                onChanged: _effectiveReadOnly ? null : (val) => setState(() {
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
                        onChanged: _effectiveReadOnly ? null : (val) => setState(() => _attendancePoints = val),
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
            if (!_effectiveReadOnly) ...[
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
            ],
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
            if (!_effectiveReadOnly) ...[
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
            ] else if (_isConfirmed) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Calificaciones confirmadas definitivamente. Plan bloqueado.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalRow(int index) {
    final e = _evaluaciones[index];
    final bool isPublished = e.containsKey('idEvaluacion');

    return InstitutionalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3, 
                child: TextField(
                  controller: e['nombre'], 
                  readOnly: _effectiveReadOnly || isPublished,
                  decoration: const InputDecoration(labelText: "Evaluación (Ej: Taller 1)")
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1, 
                child: TextField(
                  controller: e['ponderacion'], 
                  readOnly: _effectiveReadOnly || isPublished,
                  decoration: const InputDecoration(labelText: "%"), 
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: (_effectiveReadOnly || isPublished) ? Colors.grey : Colors.black),
                )
              ),
              if (!_effectiveReadOnly && !isPublished)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red), 
                  onPressed: () => setState(() => _evaluaciones.removeAt(index))
                ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _effectiveReadOnly ? null : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: (e['fecha'] as DateTime).isBefore(DateTime.now()) ? DateTime.now() : e['fecha'],
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
                  Text("Fecha programada: ${(e['fecha'] as DateTime).day}/${(e['fecha'] as DateTime).month}/${(e['fecha'] as DateTime).year}"),
                  const Spacer(),
                  if (!_effectiveReadOnly) const Icon(Icons.edit_calendar, size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
