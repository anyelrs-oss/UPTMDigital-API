import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class CarnetScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CarnetScreen({super.key, required this.userData});

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
    final bool esSolvente = widget.userData['estadoArancel'] ?? true;
    final String role = widget.userData['rol'] ?? 'Estudiante';

    final qrData = jsonEncode({
      "id": widget.userData['idEstudiante'] ?? widget.userData['idProfesor'] ?? widget.userData['idCoordinador'] ?? widget.userData['idUsuario'],
      "cedula": widget.userData['cedula'],
      "role": role,
      "solvente": esSolvente,
      "generated_at": DateTime.now().toIso8601String(),
    });

    String infoAcademica = "UPTM DIGITAL";
    if (role == 'Estudiante') {
      infoAcademica = widget.userData['carrera'] ?? 'ESTUDIANTE';
    } else if (role == 'Profesor') {
      infoAcademica = widget.userData['departamento'] ?? 'PROFESOR';
    } else if (role == 'Coordinador') {
      infoAcademica = widget.userData['carrera']?['nombre'] ?? 'COORDINADOR';
    } else {
      infoAcademica = role.toUpperCase();
    }

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
                    // Fase 8: Marca de agua de solvencia (Solo para estudiantes)
                    if (role == 'Estudiante' && !esSolvente)
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
                            backgroundImage: widget.userData['fotoUrl'] != null
                                ? NetworkImage(widget.userData['fotoUrl'])
                                : const NetworkImage('https://i.pravatar.cc/300'),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        Text(
                          "${widget.userData['nombres']} ${widget.userData['apellidos']}",
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "C.I: ${widget.userData['cedula']}",
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (role == 'Estudiante' && !esSolvente) ? Colors.red.withValues(alpha: 0.4) : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (role == 'Estudiante' && !esSolvente) ? "SOLVENCIA PENDIENTE" : infoAcademica,
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
                              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: (role == 'Estudiante' && !esSolvente) ? Colors.grey : Colors.black),
                              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: (role == 'Estudiante' && !esSolvente) ? Colors.grey : Colors.black),
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
                (role == 'Estudiante' && !esSolvente) ? "Acuda a Secretaría para solventar arancel" : "Presente este código para ingresar",
                style: TextStyle(color: (role == 'Estudiante' && !esSolvente) ? Colors.red : Colors.grey),
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
