import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _cedulaCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;

  // Estado del flujo de 2 pasos
  bool _cedulaValidada = false;
  String _nombreCompleto = '';
  String _rol = '';
  String _carrera = '';

  /// Paso 1: Validar cédula contra la Base Maestro
  Future<void> _checkCedula() async {
    final cedula = _cedulaCtrl.text.trim();
    if (cedula.isEmpty) {
      _showError('Por favor ingrese su cédula.');
      return;
    }

    setState(() => _loading = true);
    final result = await ApiService().checkCedula(cedula);
    setState(() => _loading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      if (result['yaTieneCuenta'] == true) {
        _showError('Esta cédula ya tiene una cuenta registrada. Use "Iniciar Sesión".');
        return;
      }
      setState(() {
        _cedulaValidada = true;
        _nombreCompleto = '${result['nombres']} ${result['apellidos']}';
        _rol = result['rol'] ?? '';
        _carrera = result['carrera'] ?? '';
      });
    } else {
      _showError(result['message'] ?? 'Cédula no encontrada.');
    }
  }

  /// Paso 2: Completar registro con usuario y contraseña
  Future<void> _register() async {
    if (_usuarioCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _showError('Complete todos los campos.');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showError('Las contraseñas no coinciden.');
      return;
    }
    if (_passCtrl.text.length < 4) {
      _showError('La contraseña debe tener al menos 4 caracteres.');
      return;
    }

    setState(() => _loading = true);
    final result = await ApiService().register(
      _cedulaCtrl.text.trim(),
      _usuarioCtrl.text.trim(),
      _passCtrl.text,
    );
    setState(() => _loading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '¡Registro exitoso!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context); // Volver al Login
    } else {
      _showError(result['message'] ?? 'Error en el registro.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  void _resetFlow() {
    setState(() {
      _cedulaValidada = false;
      _nombreCompleto = '';
      _rol = '';
      _carrera = '';
      _usuarioCtrl.clear();
      _passCtrl.clear();
      _confirmPassCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta UPTM'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _cedulaValidada ? Icons.verified_user : Icons.app_registration,
                  size: 80,
                  color: _cedulaValidada ? Colors.green : AppTheme.secondary,
                ),
                const SizedBox(height: 20),
                Text(
                  _cedulaValidada ? "Identidad Verificada" : "Registro Institucional",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _cedulaValidada
                      ? "Complete su registro creando un usuario y contraseña."
                      : "Ingrese su Cédula para validar su identidad en la base de datos de la universidad.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // ─── PASO 1: Cédula ───
                TextField(
                  controller: _cedulaCtrl,
                  enabled: !_cedulaValidada,
                  decoration: InputDecoration(
                    labelText: "Cédula (ej: V-20000001)",
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: _cedulaValidada
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),

                if (!_cedulaValidada) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _checkCedula,
                      icon: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text("VERIFICAR CÉDULA"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ),
                ],

                // ─── CONFIRMACIÓN DE IDENTIDAD ───
                if (_cedulaValidada) ...[
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: AppTheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _nombreCompleto,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.school, color: Colors.grey, size: 20),
                              const SizedBox(width: 12),
                              Text('$_rol — $_carrera',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _resetFlow,
                            child: const Text(
                              "¿No es usted? Cambiar cédula",
                              style: TextStyle(
                                color: AppTheme.error,
                                decoration: TextDecoration.underline,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── PASO 2: Usuario y Contraseña ───
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usuarioCtrl,
                    decoration: const InputDecoration(
                      labelText: "Crear Usuario",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Crear Contraseña",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirmar Contraseña",
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _register,
                      icon: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.how_to_reg),
                      label: const Text("COMPLETAR REGISTRO"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
