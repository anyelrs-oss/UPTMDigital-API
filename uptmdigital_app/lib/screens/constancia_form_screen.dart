import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/constancia.dart';
import 'package:uptmdigital_app/models/estudiante.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class ConstanciaFormScreen extends StatefulWidget {
  final Constancia? constancia;

  const ConstanciaFormScreen({super.key, this.constancia});

  @override
  State<ConstanciaFormScreen> createState() => _ConstanciaFormScreenState();
}

class _ConstanciaFormScreenState extends State<ConstanciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tipoController;
  late TextEditingController _estadoController;
  
  int? _selectedEstudianteId;
  List<Estudiante> _estudiantes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tipoController = TextEditingController(text: widget.constancia?.tipoConstancia ?? 'Estudios');
    _estadoController = TextEditingController(text: widget.constancia?.estado ?? 'Pendiente');
    _selectedEstudianteId = widget.constancia?.estudianteId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final estudiantesData = await ApiService().getEstudiantes();
      setState(() {
        _estudiantes = estudiantesData.map((e) => Estudiante.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _saveConstancia() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEstudianteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione estudiante')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'estudianteId': _selectedEstudianteId,
      'tipoConstancia': _tipoController.text,
      'estado': _estadoController.text,
      'fechaSolicitud': DateTime.now().toIso8601String(),
      'codigoQR': 'QR-CONST-${DateTime.now().millisecondsSinceEpoch}',
    };

    bool success;
    if (widget.constancia == null) {
      success = await ApiService().createConstancia(data);
    } else {
      data['idConstancia'] = widget.constancia!.idConstancia;
      success = await ApiService().updateConstancia(widget.constancia!.idConstancia, data);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Constancia guardada')),
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
      appBar: AppBar(title: Text(widget.constancia == null ? 'Nueva Constancia' : 'Editar Constancia')),
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
                    TextFormField(
                      controller: _tipoController,
                      decoration: const InputDecoration(labelText: 'Tipo de Constancia'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _estadoController,
                      decoration: const InputDecoration(labelText: 'Estado'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveConstancia,
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
