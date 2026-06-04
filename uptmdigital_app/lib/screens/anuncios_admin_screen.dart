import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/widgets/institutional_card.dart';

class AnunciosAdminScreen extends StatefulWidget {
  const AnunciosAdminScreen({super.key});

  @override
  State<AnunciosAdminScreen> createState() => _AnunciosAdminScreenState();
}

class _AnunciosAdminScreenState extends State<AnunciosAdminScreen> {
  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  String _prioridad = "Normal";
  int? _selectedCarreraId;
  int? _selectedRolId;
  String? _selectedTrimestre;

  List<dynamic> _carreras = [];
  List<dynamic> _roles = [];
  bool _isLoading = false;

  final List<String> _trimestres = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final carreras = await ApiService().getCarreras();
    final roles = await ApiService().getRoles();
    setState(() {
      _carreras = carreras;
      _roles = roles;
    });
  }

  Future<void> _publicar() async {
    if (_tituloCtrl.text.isEmpty || _contenidoCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);

    final data = {
      "titulo": _tituloCtrl.text,
      "contenido": _contenidoCtrl.text,
      "prioridad": _prioridad,
      "carreraId": _selectedCarreraId,
      "rolId": _selectedRolId,
      "trimestre": _selectedTrimestre,
      "autor": "Administrador"
    };

    final success = await ApiService().createAnuncio(data);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anuncio publicado exitosamente")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Anuncio")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InstitutionalCard(
              title: "Contenido del Anuncio",
              child: Column(
                children: [
                  TextField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(labelText: "Título", hintText: "Ej: Suspensión de actividades"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contenidoCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: "Contenido", hintText: "Escribe el mensaje detallado..."),
                  ),
                ],
              ),
            ),
            InstitutionalCard(
              title: "Segmentación Avanzada",
              child: Column(
                children: [
                  DropdownButtonFormField<int?>(
                    value: _selectedCarreraId,
                    decoration: const InputDecoration(labelText: "Carrera Dirigida"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todas las Carreras")),
                      ..._carreras.map((c) => DropdownMenuItem(value: c['idCarrera'], child: Text(c['nombre']))),
                    ],
                    onChanged: (val) => setState(() => _selectedCarreraId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _selectedRolId,
                    decoration: const InputDecoration(labelText: "Rol Dirigido"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todos los Roles")),
                      ..._roles.map((r) => DropdownMenuItem(value: r['idRol'], child: Text(r['nombreRol']))),
                    ],
                    onChanged: (val) => setState(() => _selectedRolId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _selectedTrimestre,
                    decoration: const InputDecoration(labelText: "Trimestre (Opcional)"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Cualquier Trimestre")),
                      ..._trimestres.map((t) => DropdownMenuItem(value: t, child: Text("Trimestre $t"))),
                    ],
                    onChanged: (val) => setState(() => _selectedTrimestre = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _prioridad,
                    decoration: const InputDecoration(labelText: "Nivel de Prioridad"),
                    items: const [
                      DropdownMenuItem(value: "Normal", child: Text("Normal (Azul)")),
                      DropdownMenuItem(value: "Urgente", child: Text("Urgente (Naranja)")),
                      DropdownMenuItem(value: "Critica", child: Text("Crítica / Alerta (Rojo)")),
                    ],
                    onChanged: (val) => setState(() => _prioridad = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _publicar,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PUBLICAR COMUNICADO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
