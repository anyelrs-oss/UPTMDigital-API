import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';

import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';
import 'package:intl/intl.dart';

class ReporteAsistenciaDocenteScreen extends StatefulWidget {
  const ReporteAsistenciaDocenteScreen({super.key});

  @override
  State<ReporteAsistenciaDocenteScreen> createState() => _ReporteAsistenciaDocenteScreenState();
}

class _ReporteAsistenciaDocenteScreenState extends State<ReporteAsistenciaDocenteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _asistencias = [];
  List<dynamic> _aperturas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = ApiService();

    // 1. Cargar asistencias institucionales (llegadas)
    final asistData = await api.getReporteAsistenciaDocente();

    // 2. Cargar solicitudes de apertura de aula
    final apertData = await api.getSolicitudesApertura();

    if (mounted) {
      setState(() {
        _asistencias = asistData;
        _aperturas = apertData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistencia Docente"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.login), text: "Llegadas"),
            Tab(icon: Icon(Icons.door_sliding), text: "Apertura Aulas"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLlegadasList(),
                _buildAperturasList(),
              ],
            ),
    );
  }

  Widget _buildLlegadasList() {
    if (_asistencias.isEmpty) return const Center(child: Text("No hay registros de llegada."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _asistencias.length,
      itemBuilder: (context, index) => _buildLlegadaItem(_asistencias[index]),
    );
  }

  Widget _buildAperturasList() {
    if (_aperturas.isEmpty) return const Center(child: Text("No hay solicitudes de apertura."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _aperturas.length,
      itemBuilder: (context, index) => _buildAperturaItem(_aperturas[index]),
    );
  }

  Widget _buildLlegadaItem(dynamic item) {
    final date = DateTime.parse(item['fecha']);
    return InstitutionalCard(
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
        title: Text(item['profesor'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Llegada: ${DateFormat('dd/MM HH:mm').format(date.toLocal())}"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text("PRESENTE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }

  Widget _buildAperturaItem(dynamic item) {
    final date = DateTime.parse(item['fechaSolicitud']);
    final String estado = item['estado'] ?? 'Pendiente';
    final Color estadoColor = estado == 'Completada' ? Colors.green : (estado == 'En Camino' ? Colors.orange : Colors.grey);

    return InstitutionalCard(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: estadoColor.withValues(alpha: 0.1), child: Icon(Icons.room, color: estadoColor)),
        title: Text("Aula: ${item['aula']?['nombre'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Solicitado por: ${item['profesor']?['nombres'] ?? 'Docente'}\n${DateFormat('dd/MM HH:mm').format(date.toLocal())}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(estado, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 11)),
            if (item['motivo'] != null) Text(item['motivo'], style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
