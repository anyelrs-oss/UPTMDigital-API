import 'package:flutter/material.dart';

class ArancelesAdminScreen extends StatefulWidget {
  const ArancelesAdminScreen({super.key});

  @override
  State<ArancelesAdminScreen> createState() => _ArancelesAdminScreenState();
}

class _ArancelesAdminScreenState extends State<ArancelesAdminScreen> {
  final List<dynamic> _validaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Note: Assuming there's an endpoint for all validations. If not, I'll mock it based on getArancelStatus loop or create a placeholder.
    // For now, I'll assume getAuditLogs might have this info or we need a new method.
    // Let's create getValidacionesArancel in ApiService.
    setState(() => _isLoading = true);
    // Simulation:
    
    // TODO: Implement getValidacionesArancel
    // For now, returning empty to avoid crash but showing the structure
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Control de Aranceles")),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Vista de supervisión de cargas de aranceles realizadas por secretaría.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _validaciones.isEmpty
                  ? const Center(child: Text("No hay registros de pago hoy."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _validaciones.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) => _buildItem(_validaciones[i]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(dynamic v) {
    return ListTile(
      leading: const Icon(Icons.receipt_long_outlined, color: Colors.blueGrey),
      title: Text("C.I: ${v['cedulaEstudiante']}"),
      subtitle: Text("Factura: ${v['numeroFactura']} • ${v['fechaValidacion'].split('T')[0]}"),
      trailing: const Icon(Icons.check_circle, color: Colors.green),
    );
  }
}
