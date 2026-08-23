import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'app.dart';
import 'config/app_flavor.dart';
import 'navigation/router_customer.dart';
import 'services/push_service.dart';

/// PitGo (mijoz) ilovasining entry point'i.
/// PitGo Pro uchun: `lib/main_pro.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFlavorConfig.current = AppFlavor.customer;
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
        child: PitGoApp(routerProvider: routerCustomerProvider),
      ),
    ),
  );
}
