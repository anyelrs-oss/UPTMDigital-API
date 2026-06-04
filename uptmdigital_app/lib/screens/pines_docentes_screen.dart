import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:intl/intl.dart';

class PinesDocentesScreen extends StatefulWidget {
  const PinesDocentesScreen({super.key});

  @override
  State<PinesDocentesScreen> createState() => _PinesDocentesScreenState();
}

import 'package:flutter/services.dart';

class _PinesDocentesScreenState extends State<PinesDocentesScreen> {
  List<dynamic> _pines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPines();
  }

  Future<void> _loadPines() async {
    setState(() => _isLoading = true);
    // Nota: Reutilizamos el endpoint actual para obtener el último pin generado
    // por cualquier coordinador, simulando la vista administrativa.
    final res = await ApiService().generarPinAsistencia(null);
    if (mounted) {
      setState(() {
        if (res['pin'] != null) _pines = [res];
        _isLoading = false;
      });
    }
  }

  void _copyPin(String pin) {
    Clipboard.setData(ClipboardData(text: pin));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PIN $pin copiado al portapapeles"), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pines de Asistencia")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPines,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Pines activos generados por los departamentos. Puede copiar el código para compartirlo si es necesario.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (_pines.isEmpty)
                    const Center(child: Text("No hay pines activos registrados."))
                  else
                    ..._pines.map((p) => _buildPinCard(p)),
                ],
              ),
            ),
    );
  }

  Widget _buildPinCard(dynamic p) {
    final expiry = DateTime.parse(p['expiracion']);
    final pin = p['pin'].toString();

    return InstitutionalCard(
      child: ListTile(
        title: Text(
          pin,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.red),
        ),
        subtitle: Text("Expira: ${DateFormat('HH:mm dd/MM').format(expiry.toLocal())}"),
        trailing: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: IconButton(
            icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
            onPressed: () => _copyPin(pin),
            tooltip: "Copiar PIN",
          ),
        ),
      ),
    );
  }
}
