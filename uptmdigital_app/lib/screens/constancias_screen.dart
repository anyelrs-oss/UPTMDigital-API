import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class ConstanciasScreen extends StatefulWidget {
  final int? studentId;
  const ConstanciasScreen({super.key, this.studentId});

  @override
  State<ConstanciasScreen> createState() => _ConstanciasScreenState();
}

class _ConstanciasScreenState extends State<ConstanciasScreen> {
  bool _showSolicitud = false;
  List<dynamic> _misConstancias = [];
  bool _isLoading = true;

  final List<String> _tiposConstancia = [
    "Constancia de Estudios",
    "Constancia de Buena Conducta",
    "Certificación de Calificaciones",
    "Constancia de Inscripción",
    "Constancia de Culminación",
    "Constancia de Pasantías",
    "Carta de Postulación",
    "Historial Académico",
    "Carnet Estudiantil (Reposición)"
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getConstancias();
    if (mounted) {
      setState(() {
        _misConstancias = data;
        if (widget.studentId != null) {
          _misConstancias = _misConstancias.where((c) => c['estudianteId'] == widget.studentId).toList();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _solicitar(String tipo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Solicitud"),
        content: Text("¿Deseas solicitar una $tipo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await ApiService().createConstancia({
        "estudianteId": widget.studentId,
        "tipoConstancia": tipo,
        "estado": "Solicitada",
        "fechaSolicitud": DateTime.now().toIso8601String(),
      });

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud enviada exitosamente")));
        _loadData();
        setState(() => _showSolicitud = false);
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al enviar solicitud")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Constancias y Certificaciones"),
        leading: _showSolicitud
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _showSolicitud = false))
          : null,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _showSolicitud ? _buildSolicitudView() : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMenuOption(
          "Ver Mis Constancias",
          "Consulta el estado de tus solicitudes previas",
          Icons.folder_shared_outlined,
          () => _showMisConstanciasModal(),
        ),
        const SizedBox(height: 16),
        _buildMenuOption(
          "Solicitar Nueva Constancia",
          "Realiza una solicitud formal ante el DAREE",
          Icons.add_task_outlined,
          () => setState(() => _showSolicitud = true),
        ),
      ],
    );
  }

  Widget _buildMenuOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InstitutionalCard(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSolicitudView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tiposConstancia.length,
      itemBuilder: (ctx, i) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(_tiposConstancia[i]),
            trailing: const Icon(Icons.send_outlined, size: 18),
            onTap: () => _solicitar(_tiposConstancia[i]),
          ),
        );
      },
    );
  }

  void _showMisConstanciasModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Mis Solicitudes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _misConstancias.isEmpty
                ? const Center(child: Text("No tienes solicitudes registradas"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _misConstancias.length,
                    itemBuilder: (ctx, i) => _buildConstanciaItem(_misConstancias[i]),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstanciaItem(dynamic c) {
    final status = c['estado'] ?? 'Solicitada';
    Color statusColor = Colors.blue;
    if (status == 'Aprobada') statusColor = Colors.green;
    if (status == 'En Proceso') statusColor = Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(c['tipoConstancia'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("Fecha: ${c['fechaSolicitud']?.split('T')[0] ?? ''}", style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}
