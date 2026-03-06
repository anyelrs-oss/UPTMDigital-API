import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // 2. Get Token
    String? token;
    try {
        if (kIsWeb) {
            // NOTE: User must replace this VAPID key with their own from Firebase Console -> Project Settings -> Cloud Messaging
            // token = await _messaging.getToken(vapidKey: "YOUR_VAPID_KEY_HERE");
            // For now, we leave it null to avoid errors if they haven't set it up, or let it fail gracefully.
             print("Web Push requires VAPID Key in getToken()");
        } else {
            token = await _messaging.getToken();
        }
    } catch(e) {
        print("Error getting token: $e");
    }
    
    if (token != null) {
      print("FCM Token: $token");
      // Save handling (e.g., send to API)
    }

    // 3. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }
    
  Future<String?> getToken() async {
      try {
           return await _messaging.getToken();
      } catch (e) {
          return null;
      }
  }
}
