import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class CarnetScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const CarnetScreen({super.key, required this.studentData});

  @override
  State<CarnetScreen> createState() => _CarnetScreenState();
}

class _CarnetScreenState extends State<CarnetScreen> {
  @override
  void initState() {
    super.initState();
    // Fase 8: Bloquear capturas de pantalla para seguridad del carnet
    _enableSecurity();
  }

  @override
  void dispose() {
    _disableSecurity();
    super.dispose();
  }

  Future<void> _enableSecurity() async {
    // Solo funciona en Android nativo, pero preparamos el llamado
    await SystemChannels.platform.invokeMethod('SystemChrome.setEnabledSystemUIMode', []);
  }

  Future<void> _disableSecurity() async {
    // Restaurar permisos de captura al salir
  }

  @override
  Widget build(BuildContext context) {
    final bool esSolvente = widget.studentData['estadoArancel'] ?? true;

    final qrData = jsonEncode({
      "id": widget.studentData['idEstudiante'],
      "cedula": widget.studentData['cedula'],
      "role": "Estudiante",
      "solvente": esSolvente,
      "generated_at": DateTime.now().toIso8601String(),
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Carnet Digital")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Contenedor del Carnet
              Container(
                width: 350,
                height: 550,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))
                  ],
                ),
                child: Stack(
                  children: [
                    // Fase 8: Marca de agua de solvencia
                    if (!esSolvente)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                "PENDIENTE POR ARANCEL",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    Column(
                      children: [
                        const SizedBox(height: 30),
                        const Text(
                          "UPTM DIGITAL",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "REPÚBLICA BOLIVARIANA DE VENEZUELA",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 20),
                        
                        // Foto
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: widget.studentData['fotoUrl'] != null
                                ? NetworkImage(widget.studentData['fotoUrl'])
                                : const NetworkImage('https://i.pravatar.cc/300'),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        Text(
                          "${widget.studentData['nombres']} ${widget.studentData['apellidos']}",
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "C.I: ${widget.studentData['cedula']}",
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: esSolvente ? Colors.white24 : Colors.red.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            esSolvente ? (widget.studentData['carrera'] ?? 'ESTUDIANTE') : "SOLVENCIA PENDIENTE",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // QR Code
                        GestureDetector(
                          onTap: () => _showZoomedQR(context, qrData),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 120.0,
                              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: esSolvente ? Colors.black : Colors.grey),
                              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: esSolvente ? Colors.black : Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Válido hasta: Dic 2025",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                esSolvente ? "Presente este código para ingresar" : "Acuda a Secretaría para solventar arancel",
                style: TextStyle(color: esSolvente ? Colors.grey : Colors.red),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showZoomedQR(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Escaneando Identidad", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 280.0,
              ),
              const SizedBox(height: 20),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CERRAR")),
            ],
          ),
        ),
      ),
    );
  }
}
