import 'package:flutter/material.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/screens/student_dashboard.dart';
import 'package:uptmdigital_app/screens/professor_dashboard.dart';
import 'package:uptmdigital_app/screens/admin_dashboard.dart';
import 'package:uptmdigital_app/screens/security_dashboard.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

/// SplashScreen con auto-login estilo redes sociales.
///
/// Al abrir la app:
///   1. Muestra el logo por ~1.5 segundos.
///   2. Verifica si hay un token guardado (FlutterSecureStorage).
///   3. Si hay token → va directo al dashboard según el rol guardado.
///   4. Si no hay token → va a LoginScreen.
///
/// El token dura 30 días. Solo se borra cuando el usuario hace logout explícito.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Espera mínima para mostrar el splash
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    final api = ApiService();
    final loggedIn = await api.isLoggedIn();

    if (!loggedIn) {
      _goTo(const LoginScreen());
      return;
    }

    // Recuperar rol guardado localmente (sin llamar al servidor)
    final role = await api.getSavedRole();

    Widget destination;
    switch (role) {
      case 'Profesor':
        destination = const ProfessorDashboard();
        break;
      case 'Administrador':
        destination = const AdminDashboard();
        break;
      case 'Seguridad':
        destination = const SecurityDashboard();
        break;
      case 'Estudiante':
      default:
        destination = const StudentDashboard();
        break;
    }

    _goTo(destination);
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 100,
                  width: 100,
                  errorBuilder: (ctx, _, __) =>
                      const Icon(Icons.school, size: 80, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "UPTM DIGITAL",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: 2.0,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tu portal universitario",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: AppTheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
