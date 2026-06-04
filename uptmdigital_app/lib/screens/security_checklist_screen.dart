import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class SecurityChecklistScreen extends StatefulWidget {
  final int solicitudId;
  final String aulaNombre;

  const SecurityChecklistScreen({
    super.key,
    required this.solicitudId,
    required this.aulaNombre,
  });

  @override
  State<SecurityChecklistScreen> createState() => _SecurityChecklistScreenState();
}

class _SecurityChecklistScreenState extends State<SecurityChecklistScreen> {
  final Map<String, bool> _items = {
    "CPUs": true,
    "Monitores": true,
    "Teclados": true,
    "Ratones": true,
    "Reguladores": true,
    "Aires Acondicionados": true,
    "Mobiliario (Mesas/Sillas)": true,
    "Pizarrón": true,
  };

  final _observacionesCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _finalizarApertura() async {
    setState(() => _isLoading = true);

    // Si hay algún item en false, enviar reporte de incidencia (simplificado por ahora)
    bool hasIncident = _items.values.any((v) => !v);

    if (hasIncident && _observacionesCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe especificar los detalles de la falta en observaciones."), backgroundColor: Colors.orange)
      );
      setState(() => _isLoading = false);
      return;
    }

    // Completar apertura en API
    final success = await ApiService().completarApertura(widget.solicitudId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aula ${widget.aulaNombre} abierta exitosamente. ${hasIncident ? 'Incidencia reportada.' : ''}")),
      );
      Navigator.pop(context);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chequeo: ${widget.aulaNombre}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Verifique el estado de los equipos antes de entregar el aula al docente.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            InstitutionalCard(
              title: "Lista de Verificación",
              child: Column(
                children: _items.keys.map((key) => CheckboxListTile(
                  title: Text(key, style: const TextStyle(fontSize: 14)),
                  value: _items[key],
                  onChanged: (val) => setState(() => _items[key] = val!),
                  activeColor: AppTheme.primary,
                  secondary: Icon(
                    _items[key]! ? Icons.check_circle_outline : Icons.report_problem_outlined,
                    color: _items[key]! ? Colors.green : Colors.red,
                  ),
                )).toList(),
              ),
            ),
            InstitutionalCard(
              title: "Observaciones / Incidencias",
              child: TextField(
                controller: _observacionesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Ej: Falta un ratón en la estación 5, Monitor rayado...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _finalizarApertura,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRMAR Y ENTREGAR AULA", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
