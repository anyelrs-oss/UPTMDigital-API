import 'package:flutter/material.dart';
import 'package:uptmdigital_app/services/notification_service.dart';
import 'package:uptmdigital_app/screens/notificaciones_screen.dart';

/// Widget reutilizable para el botón de campana con badge de notificaciones.
/// Usa ValueListenableBuilder para actualizar reactivamente el conteo.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService().unreadCount,
      builder: (context, count, _) {
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            ).then((_) {
              // Refresh count when returning from notification screen
              NotificationService().refreshCount();
            });
          },
          tooltip: count > 0 ? '$count notificaciones' : 'Notificaciones',
        );
      },
    );
  }
}
