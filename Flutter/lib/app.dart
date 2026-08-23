import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/app_flavor.dart';
import 'services/push_service.dart';
import 'store/auth_store.dart';
import 'store/theme_store.dart';
import 'theme/app_theme.dart';

/// PitGo va PitGo Pro'ning umumiy `MaterialApp.router` qobig'i — faqat
/// qaysi router (mijoz yoki pro) ishlatilishi tashqaridan beriladi
/// (`main.dart` / `main_pro.dart`), qolgan hammasi bir xil.
class PitGoApp extends ConsumerStatefulWidget {
  const PitGoApp({super.key, required this.routerProvider});
  final ProviderListenable<GoRouter> routerProvider;

  @override
  ConsumerState<PitGoApp> createState() => _PitGoAppState();
}

class _PitGoAppState extends ConsumerState<PitGoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).initialize();
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        PushService.instance.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(widget.routerProvider);
    final themeMode = ref.watch(themeProvider);

    final materialThemeMode = switch (themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: AppFlavorConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: materialThemeMode,
      routerConfig: router,
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.25,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
