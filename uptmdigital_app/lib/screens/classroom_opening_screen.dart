import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'dart:async';

class ClassroomOpeningScreen extends StatefulWidget {
  const ClassroomOpeningScreen({super.key});

  @override
  State<ClassroomOpeningScreen> createState() => _ClassroomOpeningScreenState();
}

class _ClassroomOpeningScreenState extends State<ClassroomOpeningScreen> {
  List<dynamic> _aulas = [];
  bool _isLoadingAulas = true;
  dynamic _solicitudActiva;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadAulas();
    _checkActiveRequest();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_solicitudActiva != null && _solicitudActiva['estado'] != 'Completada') {
        _checkActiveRequest();
      }
    });
  }

  Future<void> _loadAulas() async {
    final data = await ApiService().getAulas();
    if (mounted) {
      setState(() {
        _aulas = data;
        _isLoadingAulas = false;
      });
    }
  }

  Future<void> _checkActiveRequest() async {
    // Buscamos si el profesor ya tiene una solicitud pendiente o en camino
    final data = await ApiService().getSolicitudesApertura();
    if (mounted && data.isNotEmpty) {
      final active = data.firstWhere(
        (s) => s['estado'] == 'Pendiente' || s['estado'] == 'EnCamino' || s['estado'] == 'Completada',
        orElse: () => null,
      );

      if (active != null) {
        final String estado = active['estado'];
        final String motivo = active['motivo']?.toString().toLowerCase() ?? '';
        final bool isCierre = motivo.contains('cierre');
        
        if (estado == 'Completada') {
          final fechaStr = active['fechaCompletada'] ?? DateTime.now().toIso8601String();
          final fecha = DateTime.parse(fechaStr);
          // Si la completada es vieja (>2 min), la ignoramos para resetear el panel
          if (DateTime.now().difference(fecha).inMinutes > 2) {
            setState(() => _solicitudActiva = null);
            _loadAulas(); // Refrescar lista de aulas para ver si ya están libres
            return;
          }
        }
        
        setState(() => _solicitudActiva = {...active, 'tipo': isCierre ? 'Cierre' : 'Apertura'});
        if (estado == 'Completada') _loadAulas(); // Refrescar si acaba de completarse
      } else {
        setState(() => _solicitudActiva = null);
      }
    } else {
      if (mounted) setState(() => _solicitudActiva = null);
    }
  }

  void _solicitar(int aulaId) async {
    final res = await ApiService().solicitarApertura(aulaId, "Apertura de clase");
    if (res != null) {
      setState(() => _solicitudActiva = res);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud enviada")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Solicitar Apertura")),
      body: _isLoadingAulas
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_solicitudActiva != null) _buildStatusBanner(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _aulas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildAulaItem(_aulas[i]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusBanner() {
    final String estado = _solicitudActiva['estado'];
    final String tipo = _solicitudActiva['tipo'] ?? 'Apertura';
    Color color = Colors.orange;
    String texto = "Pendiente — Esperando respuesta de seguridad ($tipo)";
    IconData icon = Icons.timer_outlined;

    if (estado == 'EnCamino') {
      color = Colors.blue;
      texto = "En camino — Un oficial va hacia el aula ($tipo)";
      icon = Icons.directions_run;
    } else if (estado == 'Completada') {
      color = Colors.green;
      texto = "Completada — El aula ha sido ${tipo == 'Apertura' ? 'abierta' : 'cerrada'}";
      icon = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          if (estado == 'Completada')
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _solicitudActiva = null),
            )
        ],
      ),
    );
  }

  Widget _buildAulaItem(dynamic a) {
    final bool isOcupada = a['estado'] == 'Ocupada';
    return InstitutionalCard(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(a['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${a['edificio']} — Piso ${a['piso']}"),
        trailing: isOcupada
            ? ElevatedButton(
                onPressed: _solicitudActiva != null ? null : () => _solicitarCierre(a['idAula']),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                child: const Text("Solicitar Cierre"),
              )
            : ElevatedButton(
                onPressed: _solicitudActiva != null ? null : () => _solicitar(a['idAula']),
                child: const Text("Solicitar"),
              ),
      ),
    );
  }

  void _solicitarCierre(int aulaId) async {
    final res = await ApiService().solicitarApertura(aulaId, "Solicitud de cierre de aula");
    // Nota: Reutilizamos solicitarApertura pero con motivo de cierre. 
    // Idealmente la API debería tener un campo 'tipo' o manejar el motivo.
    if (res != null) {
      setState(() => _solicitudActiva = {...res, 'tipo': 'Cierre'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud de cierre enviada")));
    }
  }
}