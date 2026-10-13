import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uptmdigital_app/services/api_service.dart';

/// Servicio de notificaciones con polling periódico y notificaciones locales.
/// Singleton que expone [unreadCount] como ValueNotifier para badges reactivos.
class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _chatNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Conteo de notificaciones no leídas — escuchar con ValueListenableBuilder.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Timer? _pollTimer;
  bool _initialized = false;
  int _lastKnownCount = 0;

  /// Inicializa el servicio: configura notificaciones locales y arranca polling.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    // Configurar flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canal Android para chat
    const androidChannel = AndroidNotificationChannel(
      'uptm_chat',
      'Mensajes de Chat',
      description: 'Notificaciones de nuevos mensajes en el chat',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Check inmediato + polling cada 30 segundos
    await checkForNewNotifications();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized) return;
    if (state == AppLifecycleState.resumed) {
      checkForNewNotifications();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkForNewNotifications();
    });
  }

  /// Detiene el polling (al cerrar sesión).
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _pollTimer = null;
    _initialized = false;
    _lastKnownCount = 0;
    unreadCount.value = 0;
  }

  /// Consulta el conteo de no leídas y muestra notificación local si hay nuevas.
  Future<void> checkForNewNotifications() async {
    try {
      final count = await ApiService().getNotificacionesNoLeidas();
      unreadCount.value = count;

      // Si hay más que la última vez que revisamos → hay nuevas
      if (count > _lastKnownCount && _lastKnownCount >= 0) {
        final nuevas = count - _lastKnownCount;
        if (_lastKnownCount > 0) {
          // Solo mostrar local notification si no es la primera carga
          _showLocalNotification(
            title: '💬 Nuevos mensajes',
            body: 'Tienes $nuevas ${nuevas == 1 ? "mensaje nuevo" : "mensajes nuevos"}',
          );
        }
      }
      _lastKnownCount = count;
    } catch (e) {
      debugPrint('Notification poll error: $e');
    }
  }

  /// Fuerza una actualización del conteo (después de marcar como leída, etc.)
  Future<void> refreshCount() async {
    try {
      final count = await ApiService().getNotificacionesNoLeidas();
      unreadCount.value = count;
      _lastKnownCount = count;
    } catch (e) {
      debugPrint('Notification refresh error: $e');
    }
  }

  /// Muestra una notificación local del sistema.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'uptm_chat',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de nuevos mensajes en el chat',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      _chatNotificationId,
      title,
      body,
      details,
    );
  }

  /// Callback al tocar una notificación local.
  void _onNotificationTap(NotificationResponse response) {
    // Navegación se maneja en los dashboards al abrir NotificacionesScreen
    debugPrint('Notification tapped: ${response.payload}');
  }
}
