import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:uptmdigital_app/models/mensaje.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final int? asignaturaId;
  final int? peerUserId; // For Private Chat
  final int? carreraId; // For Career/Group Chat
  final String title;
  final String userName;

  const ChatScreen({
    super.key,
    this.asignaturaId,
    this.peerUserId,
    this.carreraId,
    required this.title,
    required this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late Stream<List<Mensaje>> _messageStream;
  bool _isLoading = true;
  int? _myId;
  String? _myRealName;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final storage = ApiService().storage;
    final idStr = await storage.read(key: 'user_id');
    _myRealName = await storage.read(key: 'username');
    _myId = int.tryParse(idStr ?? '');

    _messageStream = SupabaseService().getMessagesStream(
      asignaturaId: widget.asignaturaId,
      peerUserId: widget.peerUserId,
      carreraId: widget.carreraId,
      currentUserId: _myId,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    final file = File(image.path);
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subiendo imagen...")));

    final url = await SupabaseService().uploadImage(file, fileName);
    if (url != null) {
      _sendSocketMessage(content: "[Imagen]", imageUrl: url, tipo: "Imagen");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al subir imagen")));
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final content = _controller.text.trim();
    _controller.clear();
    await _sendSocketMessage(content: content, tipo: "Texto");
  }

  Future<void> _sendSocketMessage({required String content, String? imageUrl, String tipo = "Texto"}) async {
    final data = {
      "AsignaturaId": widget.asignaturaId,
      "CarreraId": widget.carreraId,
      "ReceptorUsuarioId": widget.peerUserId,
      "Contenido": content,
      "EmisorNombre": _myRealName ?? widget.userName,
      "TipoChat": widget.asignaturaId != null ? "Asignatura" : (widget.carreraId != null ? "Carrera" : "Privado"),
      "ImageUrl": imageUrl,
      "FechaEnvio": DateTime.now().toIso8601String(),
    };

    // Usamos la API para mantener consistencia y auditoría,
    // pero Supabase Realtime detectará el insert en la BD y actualizará a todos.
    final result = await ApiService().sendMensaje(data);
    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar mensaje: ${result['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String subtitle = "Chat Privado";
    if (widget.asignaturaId != null) subtitle = "Chat Grupal (Clase)";
    if (widget.carreraId != null) subtitle = "Sala de Carrera (PIN)";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Mensaje>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final messages = snapshot.data ?? [];
                if (messages.isNotEmpty) _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.usuarioId == _myId || (msg.emisorNombre == _myRealName && _myRealName != null);
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Mensaje msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[600] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) Text(msg.emisorNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
            const SizedBox(height: 2),
            if (msg.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  msg.imageUrl!,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            if (msg.imageUrl != null) const SizedBox(height: 4),
            Text(msg.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Text(
              msg.fechaEnvio.contains('T') ? msg.fechaEnvio.split('T')[1].substring(0, 5) : msg.fechaEnvio,
              style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}
