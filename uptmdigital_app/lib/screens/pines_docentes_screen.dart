import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:intl/intl.dart';

class PinesDocentesScreen extends StatefulWidget {
  const PinesDocentesScreen({super.key});

  @override
  State<PinesDocentesScreen> createState() => _PinesDocentesScreenState();
}

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
    final data = await ApiService().getPinesActivos();
    if (mounted) {
      setState(() {
        _pines = data;
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
      appBar: AppBar(title: const Text("Monitor Global de Pines")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPines,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Listado de pines activos generados hoy por cada departamento académico.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (_pines.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Text("No hay pines activos registrados.", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._pines.map((p) => _buildPinCard(p)),
                ],
              ),
            ),
    );
  }

  Widget _buildPinCard(dynamic p) {
    final expiry = DateTime.parse(p['fechaExpiracion']);
    final pin = p['pin'].toString();
    final carrera = p['carrera'] ?? 'General';
    final coord = p['coordinador'] ?? 'N/A';

    return InstitutionalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          carrera,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Coordinador: $coord", style: const TextStyle(fontSize: 12)),
            Text("Expira: ${DateFormat('HH:mm').format(expiry.toLocal())}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pin,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 2),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
              onPressed: () => _copyPin(pin),
            ),
          ],
        ),
      ),
    );
  }
}
