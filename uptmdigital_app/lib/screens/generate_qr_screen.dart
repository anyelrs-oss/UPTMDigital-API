import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';

// Force Rebuild
class GenerateQRScreen extends StatefulWidget {
  final int professorId;
  const GenerateQRScreen({Key? key, required this.professorId}) : super(key: key);

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  List<Asignatura> _asignaturas = [];
  Asignatura? _selectedAsignatura;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAsignaturas();
  }

  Future<void> _loadAsignaturas() async {
    final all = await ApiService().getAsignaturas();
    // Filter client side as usual
    if (mounted) {
      setState(() {
        _asignaturas = all.map<Asignatura>((j) => Asignatura.fromJson(j)).toList();
        
        if (widget.professorId != 0) { // Assuming 0 is invalid or check null if passed nullable
           _asignaturas = _asignaturas.where((a) => a.profesorId == widget.professorId).toList();
        }
        
        _isLoading = false;
        if (_asignaturas.isNotEmpty) _selectedAsignatura = _asignaturas.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generar QR de Asistencia")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Seleccione la asignatura para la clase de hoy:",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                DropdownButton<Asignatura>(
                  value: _selectedAsignatura,
                  isExpanded: true,
                  items: _asignaturas.map((a) {
                    return DropdownMenuItem(
                      value: a,
                      child: Text("${a.codigo} - ${a.nombre}"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedAsignatura = val);
                  },
                ),
                const SizedBox(height: 40),
                if (_selectedAsignatura != null) ...[
                  const Text(
                    "Muestre este código a los estudiantes:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: jsonEncode({
                        "asignaturaId": _selectedAsignatura!.idAsignatura,
                        "timestamp": DateTime.now().toIso8601String(),
                        "type": "attendance"
                      }),
                      size: 250,
                      version: QrVersions.auto,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Asignatura ID: ${_selectedAsignatura!.idAsignatura}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ] else
                  const Text("No tiene asignaturas asignadas."),
              ],
            ),
          ),
    );
  }
}
