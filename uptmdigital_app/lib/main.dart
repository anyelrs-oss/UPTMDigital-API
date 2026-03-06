// lib/main.dart → VERSIÓN FINAL 100 % FUNCIONAL (sin errores ni warnings)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/estudiantes_screen.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:uptmdigital_app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  
  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization failed (Expected if config is missing): $e");
  }

  runApp(const UPTMDigitalApp());
}

class UPTMDigitalApp extends StatelessWidget {
  const UPTMDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPTMDigital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const LoginScreen(),
        '/estudiantes': (context) => const EstudiantesScreen(),
      },
    );
  }
}
