import 'dart:io';
import 'dart:async';
import 'package:uptmdigital_app/models/mensaje.dart';
import 'package:uptmdigital_app/services/api_service.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();
  factory SupabaseService() => instance;

  Stream<List<Mensaje>> getMessagesStream({
    int? asignaturaId,
    int? peerUserId,
    int? carreraId,
    int? currentUserId,
  }) {
    late StreamController<List<Mensaje>> controller;
    Timer? timer;

    void fetchMessages() async {
      try {
        List<Mensaje> msgs = [];
        if (asignaturaId != null) {
          msgs = await ApiService().getMensajes(asignaturaId);
        } else if (peerUserId != null) {
          msgs = await ApiService().getMensajesPrivados(peerUserId);
        } else if (carreraId != null) {
          msgs = await ApiService().getMensajesCarrera(carreraId);
        }
        if (!controller.isClosed) {
          controller.add(msgs);
        }
      } catch (e) {
        // Ignorar errores de red temporales en el polling
      }
    }

    controller = StreamController<List<Mensaje>>(
      onListen: () {
        fetchMessages(); // Carga inicial inmediata
        timer = Timer.periodic(const Duration(seconds: 3), (t) {
          fetchMessages();
        });
      },
      onCancel: () {
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  Future<String?> uploadImage(File file, String fileName) async {
    return null;
  }

  Future<bool> deleteImage(String url) async {
    return false;
  }
}
