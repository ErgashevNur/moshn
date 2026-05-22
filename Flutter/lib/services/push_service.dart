import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await NotificationService().registerToken(token);
        } catch (e) {
          if (kDebugMode) debugPrint('Failed to register FCM token: $e');
        }
      }
      messaging.onTokenRefresh.listen((newToken) {
        NotificationService().registerToken(newToken).catchError((_) {});
      });
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Push init failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Foreground message: ${message.notification?.title}');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('Background message: ${message.notification?.title}');
  }
}
