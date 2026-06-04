import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/anuncio.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/screens/noticia_detalle_screen.dart';

class NoticiasListScreen extends StatefulWidget {
  const NoticiasListScreen({super.key});

  @override
  State<NoticiasListScreen> createState() => _NoticiasListScreenState();
}

class _NoticiasListScreenState extends State<NoticiasListScreen> {
  List<Anuncio> _noticias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNoticias();
  }

  Future<void> _loadNoticias() async {
    final data = await ApiService().getAnuncios();
    if (mounted) {
      setState(() {
        _noticias = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Noticias UPTM")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNoticias,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _noticias.length,
                itemBuilder: (ctx, i) => _buildCard(_noticias[i]),
              ),
            ),
    );
  }

  Widget _buildCard(Anuncio a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoticiaDetalleScreen(anuncio: a))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: a.prioridad == "Critica" ? Colors.red.shade100 : Colors.blue.shade100,
              child: Icon(Icons.campaign, size: 50, color: a.prioridad == "Critica" ? Colors.red : Colors.blue),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(a.contenido, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
