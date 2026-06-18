import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';

class ContactSearchScreen extends StatefulWidget {
  final int? professorId;
  const ContactSearchScreen({super.key, this.professorId});

  @override
  State<ContactSearchScreen> createState() => _ContactSearchScreenState();
}

class _ContactSearchScreenState extends State<ContactSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _profesores = [];
  List<dynamic> _estudiantes = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    
    // Si es profesor, cargamos sus estudiantes
    if (widget.professorId != null) {
      // Obtenemos sus materias primero
      final asignaturas = await api.getAsignaturas();
      final misMaterias = asignaturas.where((a) => a['profesorId'] == widget.professorId).toList();
      
      Set<int> studentIds = {};
      List<dynamic> myStudents = [];
      
      for (var m in misMaterias) {
        final inscritos = await api.getInscripcionesByAsignatura(m['idAsignatura']);
        for (var i in inscritos) {
          final estudiante = i['estudiante'];
          if (estudiante != null && !studentIds.contains(i['estudianteId'])) {
            studentIds.add(i['estudianteId']);
            myStudents.add({
              'id': estudiante['usuarioId'], // El ID de usuario para el chat privado
              'nombre': "${estudiante['nombres']} ${estudiante['apellidos']}",
              'rol': 'Estudiante',
              'cedula': estudiante['cedula']
            });
          }
        }
      }
      _estudiantes = myStudents;
    }

    // Siempre permitimos buscar otros profesores
    final profs = await api.getProfesores();
    _profesores = profs.map((p) => {
      'id': p['usuarioId'],
      'nombre': "${p['nombres']} ${p['apellidos']}",
      'rol': 'Profesor',
      'departamento': p['departamento']
    }).toList();

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredProfs = _profesores.where((p) => p['nombre'].toLowerCase().contains(_query.toLowerCase())).toList();
    final filteredStudents = _estudiantes.where((s) => s['nombre'].toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar Contacto"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Nombre del profesor o estudiante...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (filteredProfs.isNotEmpty) ...[
                      const _SectionHeader(title: "PROFESORES"),
                      ...filteredProfs.map((p) => _ContactTile(contact: p)),
                    ],
                    if (filteredStudents.isNotEmpty) ...[
                      const _SectionHeader(title: "MIS ESTUDIANTES"),
                      ...filteredStudents.map((s) => _ContactTile(contact: s)),
                    ],
                    if (filteredProfs.isEmpty && filteredStudents.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text("No se encontraron contactos."),
                        ),
                      )
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final dynamic contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        child: Text(contact['nombre'][0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
      ),
      title: Text(contact['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(contact['rol'] == 'Profesor' ? (contact['departamento'] ?? 'Profesor') : "Estudiante - ${contact['cedula']}"),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
            peerUserId: contact['id'],
            title: contact['nombre'],
            userName: "Usuario",
          ),
        ));
      },
    );
  }
}
