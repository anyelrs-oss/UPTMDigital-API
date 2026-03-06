import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:uptmdigital_app/theme.dart';

class CarnetScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const CarnetScreen({Key? key, required this.studentData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate QR Data: JSON with student identification
    // We include timestamp to allow future validation of "recency" if we want dynamic codes later
    final qrData = jsonEncode({
      "id": studentData['idEstudiante'],
      "cedula": studentData['cedula'],
      "role": "Estudiante",
      "generated_at": DateTime.now().toIso8601String(), 
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Carnet Digital")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use a Container to simulate the physical card
              Container(
                width: 350,
                height: 550,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A237E), Color(0xFF3949AB)]), // Professional Blue Gradient
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Pattern (Optional opacity)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.network(
                          "https://www.transparenttextures.com/patterns/cubes.png", // Placeholder pattern
                          repeat: ImageRepeat.repeat,
                          errorBuilder: (_,__,___) => const SizedBox(), 
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 30),
                        // University Header
                        const Text(
                          "UPTM DIGITAL",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "REPÚBLICA BOLIVARIANA DE VENEZUELA",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 20),
                        
                        // Photo
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: studentData['fotoUrl'] != null 
                                ? NetworkImage(studentData['fotoUrl']) 
                                : const NetworkImage('https://i.pravatar.cc/300'),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        // Name & Info
                        Text(
                          "${studentData['nombres']} ${studentData['apellidos']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "C.I: ${studentData['cedula']}",
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            studentData['carrera'] ?? 'ESTUDIANTE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 120.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Válido hasta: Dic 2025", // Hardcoded period for now
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Presente este código para ingresar",
                style: TextStyle(color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }
}
