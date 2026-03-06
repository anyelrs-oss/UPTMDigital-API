import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uptmdigital_app/models/mensaje.dart';
import 'package:uptmdigital_app/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int asignaturaId;
  final String asignaturaNombre;
  final String userName; // Sender name (simplified)

  const ChatScreen({
    Key? key,
    required this.asignaturaId,
    required this.asignaturaNombre,
    required this.userName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Mensaje> _messages = [];
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final msgs = await ApiService().getMensajes(widget.asignaturaId);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      // Scroll to bottom if new messages (optional: only if pending)
      // _scrollToBottom(); 
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final content = _controller.text.trim();
    _controller.clear();

    final data = {
      "asignaturaId": widget.asignaturaId,
      "contenido": content,
      "emisorNombre": widget.userName
    };

    final success = await ApiService().sendMensaje(data);
    if (success) {
      await _fetchMessages();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al enviar mensaje")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat - ${widget.asignaturaNombre}")),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text("No hay mensajes aún. ¡Di hola!"))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.emisorNombre == widget.userName;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.emisorNombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isMe ? Colors.blue[900] : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(msg.content),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.fechaEnvio.split('T')[1].substring(0, 5), // Time only
                                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
