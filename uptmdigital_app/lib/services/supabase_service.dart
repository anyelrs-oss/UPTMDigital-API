import 'dart:io';
import 'package:uptmdigital_app/models/mensaje.dart';

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
    return Stream.value([]);
  }

  Future<String?> uploadImage(File file, String fileName) async {
    return null;
  }

  Future<bool> deleteImage(String url) async {
    return false;
  }
}
