import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/theme.dart';
import 'package:uptmdigital_app/screens/chat_screen.dart';
import 'package:intl/intl.dart';

import 'package:uptmdigital_app/screens/contact_search_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final data = await ApiService().getMisChats();
    final storage = ApiService().storage;
    final profIdStr = await storage.read(key: 'profesor_id');
    final profId = int.tryParse(profIdStr ?? '');
    
    if (mounted) {
      setState(() {
        _chats = data;
        _isLoading = false;
        _myProfessorId = profId;
      });
    }
  }

  int? _myProfessorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bandeja de Entrada")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
            ? const Center(child: Text("No tienes chats activos."))
            : RefreshIndicator(
                onRefresh: _loadChats,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chats.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) => _buildChatItem(_chats[i]),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ContactSearchScreen(professorId: _myProfessorId)
          ));
        },
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildChatItem(dynamic chat) {
    final lastMsg = chat['ultimoMensaje'];
    final String preview = lastMsg != null ? lastMsg['contenido'] : "No hay mensajes aún.";
    final String time = lastMsg != null
        ? DateFormat('HH:mm').format(DateTime.parse(lastMsg['fechaEnvio']).toLocal())
        : "";

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        child: Text(chat['nombre'][0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
      ),
      title: Text(chat['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          if (chat['unreadCount'] != null && chat['unreadCount'] > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text("${chat['unreadCount']}", style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
            asignaturaId: chat['tipo'] == 'Asignatura' ? chat['id'] : null,
            peerUserId: chat['tipo'] == 'Privado' ? chat['id'] : null,
            carreraId: chat['tipo'] == 'Carrera' ? chat['id'] : null,
            title: chat['nombre'],
            userName: "Usuario",
          ),
        ));
      },
    );
  }
}
