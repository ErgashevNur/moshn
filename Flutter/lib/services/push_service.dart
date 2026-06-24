import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

// Notification channel (Android)
const _channel = AndroidNotificationChannel(
  'shina24_main',
  'Уведомления Shina24',
  description: 'Уведомления о бронированиях и услугах',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _localNotifications.initialize(initSettings);

  // Регистрируем канал в Android
  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

void showLocalNotification({
  required String title,
  required String body,
  int id = 0,
}) {
  _localNotifications.show(
    id,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

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
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await NotificationService().registerToken(token);
        } catch (e) {
          if (kDebugMode) debugPrint('Ошибка FCM-токена: $e');
        }
      }

      messaging.onTokenRefresh.listen((t) {
        NotificationService().registerToken(t).catchError((_) {});
      });

      // Foreground: локальное уведомление со звуком и вибрацией
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Ошибка инициализации push: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Shina24';
    final body = message.notification?.body ?? '';
    if (kDebugMode) debugPrint('Foreground message: $title');
    showLocalNotification(title: title, body: body);
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('Background message: ${message.notification?.title}');
  }
}
