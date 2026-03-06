import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class AsignaturaFormScreen extends StatefulWidget {
  final Asignatura? asignatura;

  const AsignaturaFormScreen({super.key, this.asignatura});

  @override
  State<AsignaturaFormScreen> createState() => _AsignaturaFormScreenState();
}

class _AsignaturaFormScreenState extends State<AsignaturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _creditosController;
  late TextEditingController _semestreController;
  late TextEditingController _departamentoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.asignatura?.codigo ?? '');
    _nombreController = TextEditingController(text: widget.asignatura?.nombre ?? '');
    _creditosController = TextEditingController(text: widget.asignatura?.creditos.toString() ?? '');
    _semestreController = TextEditingController(text: widget.asignatura?.semestre.toString() ?? '');
    _departamentoController = TextEditingController(text: widget.asignatura?.departamento ?? '');
    _loadSemestres();
  }

  List<dynamic> _semestresList = [];

  Future<void> _loadSemestres() async {
    final semestres = await ApiService().getSemestres();
    if (mounted) {
      setState(() {
        _semestresList = semestres;
        // Check if current value exists in list, if not, maybe clear or keep as is (though it's an ID)
      });
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _creditosController.dispose();
    _semestreController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _saveAsignatura() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'codigo': _codigoController.text,
      'nombre': _nombreController.text,
      'creditos': int.tryParse(_creditosController.text) ?? 0,
      'semestre': int.tryParse(_semestreController.text) ?? 1,
      'departamento': _departamentoController.text,
    };

    bool success;
    if (widget.asignatura == null) {
      success = await ApiService().createAsignatura(data);
    } else {
      data['idAsignatura'] = widget.asignatura!.idAsignatura;
      success = await ApiService().updateAsignatura(widget.asignatura!.idAsignatura, data);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asignatura guardada exitosamente')),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar asignatura')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.asignatura != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Asignatura' : 'Nueva Asignatura'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _creditosController,
                      decoration: const InputDecoration(labelText: 'Créditos'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: int.tryParse(_semestreController.text),
                      decoration: const InputDecoration(labelText: 'Semestre'),
                      items: _semestresList.map<DropdownMenuItem<int>>((item) {
                        return DropdownMenuItem<int>(
                          value: item['idSemestre'],
                          child: Text(item['nombre']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _semestreController.text = val.toString();
                        });
                      },
                      validator: (value) => value == null ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departamentoController,
                decoration: const InputDecoration(labelText: 'Departamento'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAsignatura,
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
