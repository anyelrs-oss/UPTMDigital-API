import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class SecurityQRScreen extends StatefulWidget {
  const SecurityQRScreen({super.key});

  @override
  State<SecurityQRScreen> createState() => _SecurityQRScreenState();
}

class _SecurityQRScreenState extends State<SecurityQRScreen> {
  bool _isProcessing = false;
  String _mode = "Entrada"; // Default mode

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    // Assume QR contains just the Cedula plain text or JSON. 
    // If it's pure text, use it directly. If JSON, parse it.
    // For now, assuming simple Cedula string or "cedula:12345"
    // Let's assume the QR code contains the 'Cedula' directly.
    
    // Simple verification
    final cedula = code.trim(); // Adjust parsing logic if QR format is complex

    final result = await ApiService().registrarAcceso(cedula, _mode);

    if (!mounted) return;

    if (result['success']) {
      _showResultDialog(
        title: "Acceso Permitido",
        message: "${result['nombre']}\n${result['rol']}\nMarca: $_mode",
        isSuccess: true,
      );
    } else {
      _showResultDialog(
        title: "Acceso Denegado",
        message: result['message'] ?? "Error desconocido",
        isSuccess: false,
      );
    }
  }

  void _showResultDialog({required String title, required String message, required bool isSuccess}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: isSuccess ? Colors.green : Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.cancel,
              size: 60,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(ctx);
               // Add delay before scanning again
               Future.delayed(const Duration(seconds: 2), () {
                 if(mounted) setState(() => _isProcessing = false);
               });
            },
            child: const Text("CONTINUAR"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Carnet")),
      body: Stack(
        children: [
           MobileScanner(
            onDetect: _onDetect,
          ),
          // OVERLAY FOR MODE SELECTION
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Modo:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ToggleButtons(
                      isSelected: [_mode == "Entrada", _mode == "Salida"],
                      onPressed: (index) {
                        setState(() => _mode = index == 0 ? "Entrada" : "Salida");
                      },
                      borderRadius: BorderRadius.circular(10),
                      fillColor: AppTheme.primary,
                      selectedColor: Colors.white,
                      color: Colors.black,
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("ENTRADA")),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("SALIDA")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
}
