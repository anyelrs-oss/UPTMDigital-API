import 'package:flutter/material.dart';
import 'package:uptmdigital_app/models/anuncio.dart';
import 'package:uptmdigital_app/services/api_service.dart';

class AnunciosCarousel extends StatefulWidget {
  const AnunciosCarousel({Key? key}) : super(key: key);

  @override
  State<AnunciosCarousel> createState() => _AnunciosCarouselState();
}

class _AnunciosCarouselState extends State<AnunciosCarousel> {
  late Future<List<Anuncio>> _anunciosFuture;

  @override
  void initState() {
    super.initState();
    _anunciosFuture = ApiService().getAnuncios();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Anuncio>>(
      future: _anunciosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text("No hay anuncios recientes", style: TextStyle(color: Colors.grey))),
          );
        }

        final anuncios = snapshot.data!;
        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: anuncios.length,
            itemBuilder: (context, index) {
              final anuncio = anuncios[index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(anuncio.titulo),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anuncio.fechaPublicacion.split('T')[0],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Text(anuncio.contenido),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cerrar"),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 5))],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anuncio.titulo,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          anuncio.contenido,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          anuncio.fechaPublicacion.split('T')[0],
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
