import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:uptmdigital_app/services/api_service.dart';

class QRScanScreen extends StatefulWidget {
  final int studentId;
  const QRScanScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      // Decode QR Data (Expected: { "asignaturaId": 123, ... })
      final Map<String, dynamic> data = jsonDecode(code);
      
      if (data.containsKey('asignaturaId')) {
        // Call API
        final success = await ApiService().registrarAsistenciaQR(
          widget.studentId, 
          data['asignaturaId']
        );

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Asistencia registrada exitosamente"), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Close scanner on success
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Error al registrar asistencia o ya registrada"), backgroundColor: Colors.red),
          );
           // Delay to allow reading message before scanning again
           await Future.delayed(const Duration(seconds: 2));
           setState(() => _isProcessing = false);
        }
      } else {
        throw Exception("Código QR inválido (sin asignaturaId)");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Código de Asistencia")),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
