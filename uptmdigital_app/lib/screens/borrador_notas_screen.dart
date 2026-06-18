import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'dart:convert';

class BorradorNotasScreen extends StatefulWidget {
  final int asignaturaId;
  final String asignaturaNombre;

  const BorradorNotasScreen({
    super.key,
    required this.asignaturaId,
    required this.asignaturaNombre,
  });

  @override
  State<BorradorNotasScreen> createState() => _BorradorNotasScreenState();
}

class _BorradorNotasScreenState extends State<BorradorNotasScreen> {
  List<dynamic> _estudiantes = [];
  Map<int, String> _notasBorrador = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ApiService().getInscripcionesByAsignatura(widget.asignaturaId);

    // Cargar borrador local
    final api = ApiService();
    final cached = await api.storage.read(key: 'draft_notes_${widget.asignaturaId}');
    if (cached != null) {
      final Map<String, dynamic> decoded = jsonDecode(cached);
      _notasBorrador = decoded.map((key, value) => MapEntry(int.parse(key), value.toString()));
    }

    if (mounted) {
      setState(() {
        _estudiantes = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDraft() async {
    final api = ApiService();
    final String data = jsonEncode(_notasBorrador.map((key, value) => MapEntry(key.toString(), value)));
    await api.storage.write(key: 'draft_notes_${widget.asignaturaId}', value: data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Borrador guardado localmente")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notas: ${widget.asignaturaNombre}"),
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: _saveDraft),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Las notas se guardan localmente hasta que decidas publicarlas formalmente.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _estudiantes.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final e = _estudiantes[i];
                      final estudiante = e['estudiante'] ?? {};
                      final id = e['estudianteId'];
                      return ListTile(
                        title: Text("${estudiante['nombres'] ?? ''} ${estudiante['apellidos'] ?? ''}"),
                        subtitle: Text(estudiante['cedula'] ?? ''),
                        trailing: SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(hintText: "0.0"),
                            controller: TextEditingController(text: _notasBorrador[id] ?? "")..selection = TextSelection.fromPosition(TextPosition(offset: (_notasBorrador[id] ?? "").length)),
                            onChanged: (val) => _notasBorrador[id] = val,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement formal publication to API
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Publicación formal en desarrollo...")));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white),
          child: const Text("PUBLICAR NOTAS FINALES"),
        ),
      ),
    );
  }
}
