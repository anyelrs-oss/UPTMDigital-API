import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/profesor.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class ProfessorFormScreen extends StatefulWidget {
  final Profesor? profesor;

  const ProfessorFormScreen({super.key, this.profesor});

  @override
  State<ProfessorFormScreen> createState() => _ProfessorFormScreenState();
}

class _ProfessorFormScreenState extends State<ProfessorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cedulaController;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _correoController;
  late TextEditingController _departamentoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cedulaController = TextEditingController(text: widget.profesor?.cedula ?? '');
    _nombresController = TextEditingController(text: widget.profesor?.nombres ?? '');
    _apellidosController = TextEditingController(text: widget.profesor?.apellidos ?? '');
    _correoController = TextEditingController(text: widget.profesor?.correoInstitucional ?? '');
    _departamentoController = TextEditingController(text: widget.profesor?.departamento ?? '');
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfesor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'cedula': _cedulaController.text,
      'nombres': _nombresController.text,
      'apellidos': _apellidosController.text,
      'correoInstitucional': _correoController.text,
      'departamento': _departamentoController.text,
    };

    bool success;
    if (widget.profesor == null) {
      success = await ApiService().createProfesor(data);
    } else {
      data['idProfesor'] = widget.profesor!.idProfesor;
      success = await ApiService().updateProfesor(widget.profesor!.idProfesor, data);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profesor guardado exitosamente')),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar profesor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profesor != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Profesor' : 'Nuevo Profesor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(labelText: 'Cédula'),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(labelText: 'Nombres'),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidosController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo Institucional'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departamentoController,
                decoration: const InputDecoration(labelText: 'Departamento'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfesor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'Actualizar' : 'Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
