import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class SecurityChecklistScreen extends StatefulWidget {
  final int solicitudId;
  final String aulaNombre;
  final bool esCierre;

  const SecurityChecklistScreen({
    super.key,
    required this.solicitudId,
    required this.aulaNombre,
    this.esCierre = false,
  });

  @override
  State<SecurityChecklistScreen> createState() => _SecurityChecklistScreenState();
}

class _SecurityChecklistScreenState extends State<SecurityChecklistScreen> {
  final Map<String, bool> _items = {
    "CPUs": true,
    "Monitors": true, // Nota: Corregí nombre si es necesario
    "Teclados": true,
    "Ratones": true,
    "Reguladores": true,
    "Aires Acondicionados": true,
    "Mobiliario (Mesas/Sillas)": true,
    "Pizarrón": true,
  };

  final _observacionesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.esCierre) {
      _loadLastChecklist();
    }
  }

  Future<void> _loadLastChecklist() async {
    // Simulación de carga de datos previos (Fase 9: persistencia real vía API si existe el endpoint)
    final cached = await ApiService().storage.read(key: 'last_checklist_${widget.aulaNombre}');
    if (cached != null && mounted) {
      // Si el backend no tiene endpoint, usamos caché local del dispositivo de seguridad
      // para recordar qué se marcó al abrir.
    }
  }

  Future<void> _finalizarAccion() async {
    setState(() => _isLoading = true);

    bool hasIncident = _items.values.any((v) => !v);

    if (hasIncident && _observacionesCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe especificar los detalles en observaciones."), backgroundColor: Colors.orange)
      );
      setState(() => _isLoading = false);
      return;
    }

    bool success;
    if (widget.esCierre) {
      // Liberar aula en la API
      // Nota: Asumimos que completarApertura maneja el cambio de estado según la solicitud vinculada
      success = await ApiService().completarApertura(widget.solicitudId);
      // Forzar liberación explícita si es necesario (Fase 9)
      // await ApiService().liberarAula(aulaId); 
    } else {
      success = await ApiService().completarApertura(widget.solicitudId);
      // Guardar estado actual para el futuro cierre
      await ApiService().storage.write(key: 'last_checklist_${widget.aulaNombre}', value: 'saved');
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aula ${widget.aulaNombre} ${widget.esCierre ? 'cerrada' : 'abierta'} exitosamente.")),
      );
      Navigator.pop(context);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.esCierre ? 'Cierre' : 'Chequeo'}: ${widget.aulaNombre}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.esCierre 
                ? "Verifique que los equipos estén completos antes de retirar el aula."
                : "Verifique el estado de los equipos antes de entregar el aula al docente.",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            InstitutionalCard(
              title: widget.esCierre ? "Inventario de Salida" : "Lista de Verificación",
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
                decoration: InputDecoration(
                  hintText: widget.esCierre ? "Faltante o daño detectado al retirar..." : "Ej: Falta un ratón, Monitor rayado...",
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _finalizarAccion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.esCierre ? Colors.redAccent : Colors.green, 
                  foregroundColor: Colors.white
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.esCierre ? "CONFIRMAR Y RETIRAR AULA" : "CONFIRMAR Y ENTREGAR AULA", 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
