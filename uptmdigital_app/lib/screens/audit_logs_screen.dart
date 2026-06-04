import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:intl/intl.dart';

class AuditLogsScreen extends StatefulWidget {
  final String? filterAction; // NULL for changes (POST/PUT/DELETE), or 'GET' for routes

  const AuditLogsScreen({super.key, this.filterAction});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getAuditLogs();
    if (mounted) {
      setState(() {
        if (widget.filterAction == 'GET') {
          _logs = data.where((l) => l['accion'] == 'GET').toList();
        } else {
          _logs = data.where((l) => l['accion'] != 'GET').toList();
        }
        _isLoading = false;
      });
    }
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'POST': return Colors.green;
      case 'PUT': return Colors.blue;
      case 'DELETE': return Colors.red;
      case 'GET': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primary,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F)),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.filterAction == 'GET' ? "Bitácora de Ruta" : "Bitácora de Acciones")),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadLogs,
                child: _logs.isEmpty
                  ? const Center(child: Text("No hay registros en este periodo.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final date = DateTime.parse(log['fecha']);
                        final String user = log['usuario']?['nombreUsuario'] ?? 'Sistema/Anon';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: const Color(0xFF1E1E1E),
                          child: ExpansionTile(
                            leading: Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: _getMethodColor(log['accion']).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _getMethodColor(log['accion'])),
                              ),
                              child: Text(
                                log['accion'],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _getMethodColor(log['accion']), fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                            title: Text(log['ruta'], style: const TextStyle(fontSize: 13, color: Colors.white70)),
                            subtitle: Text("$user • ${DateFormat('HH:mm:ss dd/MM').format(date.toLocal())}", style: const TextStyle(fontSize: 11)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _detailRow("IP Origen:", log['ip']),
                                    if (log['motivoJustificado'] != null && log['motivoJustificado'].toString().isNotEmpty)
                                      _detailRow("Justificación:", log['motivoJustificado'], isAlert: true),
                                    const SizedBox(height: 8),
                                    Text("Fecha Completa: ${date.toLocal()}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
              ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isAlert ? Colors.orange : Colors.white,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.normal
              )
            )
          ),
        ],
      ),
    );
  }
}
