import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';

class AsistenciaManualScreen extends StatefulWidget {
  final int asignaturaId;
  final String asignaturaNombre;

  const AsistenciaManualScreen({
    super.key,
    required this.asignaturaId,
    required this.asignaturaNombre,
  });

  @override
  State<AsistenciaManualScreen> createState() => _AsistenciaManualScreenState();
}

class _AsistenciaManualScreenState extends State<AsistenciaManualScreen> {
  List<dynamic> _estudiantes = [];
  final Set<int> _presentes = {};
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadEstudiantes();
  }

  Future<void> _loadEstudiantes() async {
    final api = ApiService();
    final data = await api.getInscripcionesByAsignatura(widget.asignaturaId);
    if (mounted) {
      setState(() {
        _estudiantes = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarAsistencia() async {
    setState(() => _isLoading = true);
    final api = ApiService();

    int count = 0;
    for (var id in _presentes) {
      final success = await api.registrarAsistenciaQR(id, widget.asignaturaId);
      if (success) count++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Se registraron $count asistencias manualmente.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _estudiantes.where((e) {
      final name = "${e['nombres']} ${e['apellidos']}".toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || e['cedula'].contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Pase de Lista: ${widget.asignaturaNombre}")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar estudiante...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final e = filtered[i];
                      final id = e['estudianteId'];
                      final isSelected = _presentes.contains(id);

                      return Card(
                        child: CheckboxListTile(
                          title: Text("${e['nombres']} ${e['apellidos']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("C.I: ${e['cedula']}"),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val!) {
                                _presentes.add(id);
                              } else {
                                _presentes.remove(id);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundColor: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                            child: Icon(isSelected ? Icons.check : Icons.person_outline, color: isSelected ? Colors.green : Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("${_presentes.length} estudiantes seleccionados como presentes", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _presentes.isEmpty ? null : _guardarAsistencia,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("CONFIRMAR ASISTENCIA MANUAL"),
          ),
        ],
      ),
    );
  }
}
