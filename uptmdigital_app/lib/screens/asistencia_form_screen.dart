import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/asistencia.dart';
import 'package:uptmdigital_app/models/estudiante.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class AsistenciaFormScreen extends StatefulWidget {
  final Asistencia? asistencia;

  const AsistenciaFormScreen({super.key, this.asistencia});

  @override
  State<AsistenciaFormScreen> createState() => _AsistenciaFormScreenState();
}

class _AsistenciaFormScreenState extends State<AsistenciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedEstudianteId;
  int? _selectedAsignaturaId;
  DateTime _selectedDate = DateTime.now();
  
  List<Estudiante> _estudiantes = [];
  List<Asignatura> _asignaturas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedEstudianteId = widget.asistencia?.estudianteId;
    _selectedAsignaturaId = widget.asistencia?.asignaturaId;
    if (widget.asistencia != null) {
      _selectedDate = DateTime.tryParse(widget.asistencia!.fecha) ?? DateTime.now();
    }
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

  Future<void> _saveAsistencia() async {
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
      'fecha': _selectedDate.toIso8601String(),
      'codigoQR': 'QR-ASIST-${DateTime.now().millisecondsSinceEpoch}',
    };

    bool success;
    if (widget.asistencia == null) {
      success = await ApiService().createAsistencia(data);
    } else {
      data['idAsistencia'] = widget.asistencia!.idAsistencia;
      success = await ApiService().updateAsistencia(widget.asistencia!.idAsistencia, data);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia guardada')),
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
      appBar: AppBar(title: Text(widget.asistencia == null ? 'Nueva Asistencia' : 'Editar Asistencia')),
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
                    ListTile(
                      title: const Text("Fecha"),
                      subtitle: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveAsistencia,
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
