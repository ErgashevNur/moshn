import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'app.dart';
import 'config/app_flavor.dart';
import 'navigation/router_pro.dart';
import 'services/push_service.dart';

/// PitGo Pro (servis egasi / usta / evakuator) ilovasining entry point'i.
/// Mijoz ilovasi uchun: `lib/main.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFlavorConfig.current = AppFlavor.pro;
  await EasyLocalization.ensureInitialized();
  await initLocalNotifications();
  AndroidYandexMap.useAndroidViewSurface = true;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      startLocale: const Locale('ru'),
      child: ProviderScope(
        child: PitGoApp(routerProvider: routerProProvider),
      ),
    ),
  );
}
