import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/anuncio.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:intl/intl.dart';

class NoticiaDetalleScreen extends StatelessWidget {
  final Anuncio anuncio;

  const NoticiaDetalleScreen({super.key, required this.anuncio});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(anuncio.fechaPublicacion);

    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Noticia")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image or Gradient
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: anuncio.prioridad == "Critica"
                    ? [Colors.red.shade700, Colors.red.shade400]
                    : anuncio.prioridad == "Urgente"
                      ? [Colors.orange.shade700, Colors.orange.shade400]
                      : [AppTheme.primary, Colors.blue.shade400]
                ),
              ),
              child: Center(
                child: Icon(
                  anuncio.prioridad == "Critica" ? Icons.warning_amber_rounded : Icons.campaign_outlined,
                  size: 80,
                  color: Colors.white24,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: anuncio.prioridad == "Critica" ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          anuncio.prioridad.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMMM, yyyy').format(date.toLocal()),
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    anuncio.titulo,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Por: ${anuncio.autor ?? 'Administración'}",
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Divider(height: 40),
                  Text(
                    anuncio.contenido,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
