import 'package:flutter/material.dart';
import 'package:uptmdigital_app/screens/login_screen.dart';
import 'package:uptmdigital_app/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    // Simulate initial loading or check auth status
    await Future.delayed(const Duration(seconds: 3)); 
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container with Shadow
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
                errorBuilder: (ctx, _, __) => const Icon(Icons.school, size: 80, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 30),
            
            // App Name with Animation or Style
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
            
            // Loading Indicator
            const CircularProgressIndicator(
              color: AppTheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
