import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class ClassroomOpeningScreen extends StatefulWidget {
  const ClassroomOpeningScreen({super.key});

  @override
  State<ClassroomOpeningScreen> createState() => _ClassroomOpeningScreenState();
}

class _ClassroomOpeningScreenState extends State<ClassroomOpeningScreen> {
  bool _isProcessing = false;
  
  // Mock rooms for now, ideally fetched from backend
  final List<String> _rooms = ["Aula 1", "Aula 2", "Aula 3", "Lab 1", "Lab 2", "Auditorio"];
  String? _selectedRoom;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    // Assume QR code contains Professor ID or Cedula.
    // We'll simulate fetching professor info based on this ID.
    // For prototype, we show a dialog to select the room.
    
    _showRoomSelectionDialog(code);
  }

  void _showRoomSelectionDialog(String professorIdOrCedula) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Seleccionar Aula"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Código Profesor Detectado"),
                Text(professorIdOrCedula, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Aula a abrir"),
                  items: _rooms.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedRoom = val);
                  },
                  value: _selectedRoom,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetScan();
                },
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: _selectedRoom == null ? null : () {
                  Navigator.pop(ctx);
                  _processOpening(professorIdOrCedula, _selectedRoom!);
                },
                child: const Text("Confirmar Apertura"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _processOpening(String professorId, String room) async {
    // Call API to log opening
    // For now, mock it or call a new method in ApiService
    final success = await ApiService().registrarAperturaAula(professorId, room);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(success ? "Éxito" : "Error"),
        content: Text(success ? "Aula $room abierta por profesor." : "Error al registrar apertura."),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(ctx);
               _resetScan();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _isProcessing = false;
      _selectedRoom = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apertura de Aulas")),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_isProcessing)
            Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white.withOpacity(0.9),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Escanee el QR del Profesor para autorizar la apertura.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
