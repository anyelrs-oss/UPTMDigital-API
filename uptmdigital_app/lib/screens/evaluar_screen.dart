import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class EvaluarScreen extends StatefulWidget {
  final int asignaturaId;
  final String asignaturaNombre;

  const EvaluarScreen({
    super.key,
    required this.asignaturaId,
    required this.asignaturaNombre,
  });

  @override
  State<EvaluarScreen> createState() => _EvaluarScreenState();
}

class _EvaluarScreenState extends State<EvaluarScreen> {
  List<dynamic> _estudiantes = [];
  List<dynamic> _planEvaluacion = [];
  dynamic _selectedEval;
  bool _isLoading = true;
  final Map<int, TextEditingController> _notasControllers = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final api = ApiService();
    final plan = await api.getEvaluaciones(widget.asignaturaId);
    final alumnos = await api.getInscripcionesByAsignatura(widget.asignaturaId);

    if (mounted) {
      setState(() {
        _planEvaluacion = plan;
        _estudiantes = alumnos;
        if (_planEvaluacion.isNotEmpty) _selectedEval = _planEvaluacion.first;
        for (var e in _estudiantes) {
          _notasControllers[e['estudianteId']] = TextEditingController();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _publicarNotas() async {
    if (_selectedEval == null) return;

    // Validar que al menos haya una nota ingresada
    final Map<int, double> notasParaSubir = {};
    for (var entry in _notasControllers.entries) {
      if (entry.value.text.isNotEmpty) {
        final val = double.tryParse(entry.value.text);
        if (val != null) {
          notasParaSubir[entry.key] = val;
        }
      }
    }

    if (notasParaSubir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se ingresaron notas válidas.")));
      return;
    }

    setState(() => _isLoading = true);

    final success = await ApiService().createNotasMasivo(
      widget.asignaturaId,
      _selectedEval['idEvaluacion'],
      notasParaSubir
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notas subidas exitosamente.")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al subir notas al servidor."), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carga de Calificaciones")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPlanSelector(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _estudiantes.length,
                    itemBuilder: (ctx, i) => _buildEstudianteRow(_estudiantes[i]),
                  ),
                ),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. Seleccione la Evaluación:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<dynamic>(
            value: _selectedEval,
            decoration: InputDecoration(fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: _planEvaluacion.map((e) => DropdownMenuItem(value: e, child: Text("${e['nombre']} (${e['ponderacion']}%)"))).toList(),
            onChanged: (val) => setState(() => _selectedEval = val),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudianteRow(dynamic e) {
    final id = e['estudianteId'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text("${e['nombres']} ${e['apellidos']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(e['cedula'], style: const TextStyle(fontSize: 12)),
        trailing: SizedBox(
          width: 70,
          child: TextField(
            controller: _notasControllers[id],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "0.0",
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: ElevatedButton(
        onPressed: _publicarNotas,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
        child: const Text("GUARDAR CALIFICACIONES", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
