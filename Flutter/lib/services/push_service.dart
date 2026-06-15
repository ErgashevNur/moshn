import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../navigation/router.dart' as app_router;
import 'notification_service.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

// Notification channel (Android)
const _channel = AndroidNotificationChannel(
  'shina24_main',
  'Shina24 Bildirishnomalar',
  description: 'Bron va xizmat bildirishnomalari',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onLocalNotificationTap,
    onDidReceiveBackgroundNotificationResponse: _onLocalNotificationTap,
  );

  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

@pragma('vm:entry-point')
void _onLocalNotificationTap(NotificationResponse response) {
  final ctx = app_router.navigatorKey.currentContext;
  if (ctx != null) {
    GoRouter.of(ctx).push('/notifications');
  }
}

void _navigateFromRemoteMessage(RemoteMessage message) {
  final ctx = app_router.navigatorKey.currentContext;
  if (ctx == null) return;
  final router = GoRouter.of(ctx);
  final data = message.data;
  if (data['booking_id'] != null) {
    router.push('/owner/bookings/${data['booking_id']}');
  } else if (data['route'] != null) {
    router.push(data['route'] as String);
  } else {
    router.push('/notifications');
  }
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

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await NotificationService().registerToken(token);
        } catch (e) {
          if (kDebugMode) debugPrint('FCM token xatosi: $e');
        }
      }

      messaging.onTokenRefresh.listen((t) {
        NotificationService().registerToken(t).catchError((_) {});
      });

      // App o'ldirilgan holda notification tap — app ochiladi
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _navigateFromRemoteMessage(initialMessage);
        });
      }

      // App background'da — notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromRemoteMessage);

      // Foreground: local notification bilan ovoz + vibro
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Push init xatosi: $e');
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
