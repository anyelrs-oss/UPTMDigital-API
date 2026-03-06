import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/inscripcion.dart';
import 'package:uptmdigital_app/models/estudiante.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class InscripcionFormScreen extends StatefulWidget {
  final Inscripcion? inscripcion;

  const InscripcionFormScreen({super.key, this.inscripcion});

  @override
  State<InscripcionFormScreen> createState() => _InscripcionFormScreenState();
}

class _InscripcionFormScreenState extends State<InscripcionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _periodoController;
  late TextEditingController _estadoController;
  
  int? _selectedEstudianteId;
  int? _selectedAsignaturaId;
  
  List<Estudiante> _estudiantes = [];
  List<Asignatura> _asignaturas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _periodoController = TextEditingController(text: widget.inscripcion?.periodo ?? '');
    _estadoController = TextEditingController(text: widget.inscripcion?.estado ?? 'Inscrito');
    _selectedEstudianteId = widget.inscripcion?.estudianteId;
    _selectedAsignaturaId = widget.inscripcion?.asignaturaId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final estudiantesData = await ApiService().getEstudiantes();
      final asignaturasData = await ApiService().getAsignaturas();
      
      setState(() {
        _estudiantes = estudiantesData.map((e) => Estudiante.fromJson(e)).toList();
        _asignaturas = asignaturasData.map((a) => Asignatura.fromJson(a)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _periodoController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _saveInscripcion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEstudianteId == null || _selectedAsignaturaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione estudiante y asignatura')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'estudianteId': _selectedEstudianteId,
      'asignaturaId': _selectedAsignaturaId,
      'periodo': _periodoController.text,
      'estado': _estadoController.text,
      'fechaInscripcion': DateTime.now().toIso8601String(),
    };

    bool success;
    if (widget.inscripcion == null) {
      success = await ApiService().createInscripcion(data);
    } else {
      data['idInscripcion'] = widget.inscripcion!.idInscripcion;
      success = await ApiService().updateInscripcion(widget.inscripcion!.idInscripcion, data);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripción guardada')),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.inscripcion == null ? 'Nueva Inscripción' : 'Editar Inscripción')),
      body: _isLoading && _estudiantes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedEstudianteId,
                      decoration: const InputDecoration(labelText: 'Estudiante'),
                      items: _estudiantes.map((e) {
                        return DropdownMenuItem(
                          value: e.idEstudiante,
                          child: Text("${e.nombres} ${e.apellidos}"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedEstudianteId = val),
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedAsignaturaId,
                      decoration: const InputDecoration(labelText: 'Asignatura'),
                      items: _asignaturas.map((a) {
                        return DropdownMenuItem(
                          value: a.idAsignatura,
                          child: Text(a.nombre),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAsignaturaId = val),
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _periodoController,
                      decoration: const InputDecoration(labelText: 'Periodo (ej. 2024-1)'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _estadoController,
                      decoration: const InputDecoration(labelText: 'Estado'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveInscripcion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
