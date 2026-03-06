import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/estudiante.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class StudentFormScreen extends StatefulWidget {
  final Estudiante? estudiante;

  const StudentFormScreen({super.key, this.estudiante});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cedulaController;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _correoController;
  late TextEditingController _carreraController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cedulaController = TextEditingController(text: widget.estudiante?.cedula ?? '');
    _nombresController = TextEditingController(text: widget.estudiante?.nombres ?? '');
    _apellidosController = TextEditingController(text: widget.estudiante?.apellidos ?? '');
    _correoController = TextEditingController(text: widget.estudiante?.correoInstitucional ?? '');
    _carreraController = TextEditingController(text: widget.estudiante?.carrera ?? '');
    _loadCarreras();
  }

  List<dynamic> _carrerasList = [];

  Future<void> _loadCarreras() async {
    final carreras = await ApiService().getCarreras();
    if (mounted) {
      setState(() => _carrerasList = carreras);
    }
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _carreraController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> studentData = {
      'cedula': _cedulaController.text,
      'nombres': _nombresController.text,
      'apellidos': _apellidosController.text,
      'correoInstitucional': _correoController.text,
      'carrera': _carreraController.text,
      // Add other fields if necessary, backend might expect them
    };

    bool success;
    if (widget.estudiante == null) {
      success = await ApiService().createStudent(studentData);
    } else {
      // Ensure ID is passed for update
      studentData['idEstudiante'] = widget.estudiante!.idEstudiante;
      success = await ApiService().updateStudent(widget.estudiante!.idEstudiante, studentData);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante guardado exitosamente')),
      );
      Navigator.pop(context, true); // Return true to indicate refresh needed
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar estudiante')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.estudiante != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Estudiante' : 'Nuevo Estudiante'),
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
              DropdownButtonFormField<String>(
                value: _carreraController.text.isNotEmpty ? _carreraController.text : null,
                decoration: const InputDecoration(labelText: 'Carrera'),
                items: _carrerasList.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['nombre'], // Storing Name as Estudiante model uses String
                    child: Text(item['nombre']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _carreraController.text = val ?? '';
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveStudent,
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
