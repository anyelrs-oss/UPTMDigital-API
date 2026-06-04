import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:uptmdigital_app/models/asignatura.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class GenerateQRScreen extends StatefulWidget {
  final int professorId;
  const GenerateQRScreen({super.key, required this.professorId});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  List<Asignatura> _asignaturas = [];
  Asignatura? _selectedAsignatura;
  bool _isLoading = true;
  bool _pinValidated = false;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAsignaturas();
  }

  Future<void> _loadAsignaturas() async {
    final all = await ApiService().getAsignaturas();
    if (mounted) {
      setState(() {
        final list = all.map<Asignatura>((j) => Asignatura.fromJson(j)).toList();
        _asignaturas = list.where((a) => a.profesorId == widget.professorId).toList();
        _isLoading = false;
        if (_asignaturas.isNotEmpty) _selectedAsignatura = _asignaturas.first;
      });
    }
  }

  Future<void> _validatePin() async {
    if (_pinController.text.isEmpty) return;

    final success = await ApiService().validarPinDocente(_pinController.text);
    if (success) {
      setState(() => _pinValidated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN inválido o expirado. Solicite uno nuevo al coordinador.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asistencia con QR")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: !_pinValidated ? _buildPinEntry() : _buildQRGenerator(),
          ),
    );
  }

  Widget _buildPinEntry() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_person_outlined, size: 80, color: AppTheme.primary),
        const SizedBox(height: 20),
        const Text(
          "Validación Docente Requerida",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        const SizedBox(height: 10),
        const Text(
          "Ingrese el PIN diario generado por la coordinación para habilitar el QR de asistencia.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: "000000",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _validatePin,
            child: const Text("VALIDAR PIN", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildQRGenerator() {
    return Column(
      children: [
        DropdownButtonFormField<Asignatura>(
          value: _selectedAsignatura,
          decoration: const InputDecoration(labelText: "Seleccionar Asignatura"),
          items: _asignaturas.map((a) {
            return DropdownMenuItem(value: a, child: Text(a.nombre));
          }).toList(),
          onChanged: (val) => setState(() => _selectedAsignatura = val),
        ),
        const SizedBox(height: 40),
        if (_selectedAsignatura != null) ...[
          const Text(
            "Código QR de Asistencia",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
          const SizedBox(height: 20),
          Text(
            _selectedAsignatura!.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          const Text("Válido solo para esta sesión", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ],
    );
  }
}