import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/api_service.dart';
import 'package:uptmdigital_app/services/notification_service.dart';
import 'package:uptmdigital_app/theme.dart';

/// Centro de notificaciones del usuario.
/// Muestra lista de notificaciones con estado leída/no-leída,
/// acciones de marcar como leída y eliminar.
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<dynamic> _notificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificaciones();
  }

  Future<void> _loadNotificaciones() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getNotificaciones();
    if (mounted) {
      setState(() {
        _notificaciones = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarTodasLeidas() async {
    final success = await ApiService().marcarTodasNotificacionesLeidas();
    if (success) {
      await NotificationService().refreshCount();
      _loadNotificaciones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Todas las notificaciones marcadas como leídas")),
        );
      }
    }
  }

  Future<void> _marcarLeida(int id) async {
    await ApiService().marcarNotificacionLeida(id);
    await NotificationService().refreshCount();
    _loadNotificaciones();
  }

  Future<void> _eliminar(int id) async {
    await ApiService().eliminarNotificacion(id);
    await NotificationService().refreshCount();
    _loadNotificaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
        actions: [
          if (_notificaciones.any((n) => n['leida'] == false))
            TextButton.icon(
              onPressed: _marcarTodasLeidas,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text("Leer todas", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotificaciones,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notificaciones.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = _notificaciones[index];
                      return _buildNotificationTile(n);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No tienes notificaciones",
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            "Aquí aparecerán los mensajes nuevos",
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> n) {
    final bool leida = n['leida'] == true;
    final String tipo = n['tipo'] ?? 'Sistema';
    final String titulo = n['titulo'] ?? 'Notificación';
    final String cuerpo = n['cuerpo'] ?? '';
    final int id = n['idNotificacion'] ?? 0;
    
    // Parse fecha
    String fechaStr = '';
    if (n['fechaCreacion'] != null) {
      try {
        final fecha = DateTime.parse(n['fechaCreacion']).toLocal();
        final now = DateTime.now();
        final diff = now.difference(fecha);
        if (diff.inMinutes < 1) {
          fechaStr = 'Ahora';
        } else if (diff.inMinutes < 60) {
          fechaStr = 'Hace ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          fechaStr = 'Hace ${diff.inHours}h';
        } else if (diff.inDays < 7) {
          fechaStr = 'Hace ${diff.inDays}d';
        } else {
          fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
        }
      } catch (_) {}
    }

    IconData icon;
    Color iconColor;
    switch (tipo) {
      case 'Chat':
        icon = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      case 'Academica':
        icon = Icons.school;
        iconColor = Colors.green;
        break;
      case 'Evaluacion':
        icon = Icons.assignment;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key('notif_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _eliminar(id),
      child: ListTile(
        tileColor: leida ? null : AppTheme.primary.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            if (!leida)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: leida ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cuerpo.isNotEmpty)
              Text(cuerpo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(fechaStr, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ],
        ),
        trailing: !leida
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                color: Colors.grey,
                onPressed: () => _marcarLeida(id),
                tooltip: 'Marcar como leída',
              )
            : null,
        onTap: () {
          if (!leida) _marcarLeida(id);
        },
      ),
    );
  }
}
