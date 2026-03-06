import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';

class AdminMaintenanceScreen extends StatefulWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  State<AdminMaintenanceScreen> createState() => _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState extends State<AdminMaintenanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Lists
  List<dynamic> _carreras = [];
  List<dynamic> _semestres = [];
  List<dynamic> _periodos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final carreras = await ApiService().getCarreras();
    final semestres = await ApiService().getSemestres();
    final periodos = await ApiService().getPeriodos();

    if (mounted) {
      setState(() {
        _carreras = carreras;
        _semestres = semestres;
        _periodos = periodos;
        _isLoading = false;
      });
    }
  }

  Future<void> _addItem(String type) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Agregar $type"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nombre"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                bool success = false;
                if (type == "Carrera") success = await ApiService().addCarrera(controller.text);
                if (type == "Semestre") success = await ApiService().addSemestre(controller.text);
                if (type == "Periodo") success = await ApiService().addPeriodo(controller.text);

                if (success && mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String type, int id) async {
    bool success = await ApiService().deleteAdminData(type.toLowerCase() + "s", id);
    if (success) _loadData();
  }

  Widget _buildList(List<dynamic> items, String type, String idKey, String nameKey) {
    if (items.isEmpty) return const Center(child: Text("No hay datos."));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(item[nameKey] ?? '-'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(type, item[idKey]),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mantenimiento"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Carreras"),
            Tab(text: "Semestres"),
            Tab(text: "Periodos"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                Scaffold(
                  floatingActionButton: FloatingActionButton(
                    heroTag: "btn1",
                    onPressed: () => _addItem("Carrera"),
                    child: const Icon(Icons.add),
                  ),
                  body: _buildList(_carreras, "Carrera", "idCarrera", "nombre"),
                ),
                Scaffold(
                  floatingActionButton: FloatingActionButton(
                    heroTag: "btn2",
                    onPressed: () => _addItem("Semestre"),
                    child: const Icon(Icons.add),
                  ),
                  body: _buildList(_semestres, "Semestre", "idSemestre", "nombre"),
                ),
                Scaffold(
                  floatingActionButton: FloatingActionButton(
                    heroTag: "btn3",
                    onPressed: () => _addItem("Periodo"),
                    child: const Icon(Icons.add),
                  ),
                  body: _buildList(_periodos, "Periodo", "idPeriodo", "nombre"),
                ),
              ],
            ),
    );
  }
}
