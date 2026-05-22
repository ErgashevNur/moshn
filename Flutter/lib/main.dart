import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation/router.dart';
import 'services/push_service.dart';
import 'store/auth_store.dart';
import 'store/theme_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('uz'),
      startLocale: const Locale('uz'),
      child: const ProviderScope(child: MoshnApp()),
    ),
  );
}

class MoshnApp extends ConsumerStatefulWidget {
  const MoshnApp({super.key});

  @override
  ConsumerState<MoshnApp> createState() => _MoshnAppState();
}

class _MoshnAppState extends ConsumerState<MoshnApp> {
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
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final brightness = switch (themeMode) {
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
      AppThemeMode.system => platformBrightness,
    };

    return CupertinoApp.router(
      title: 'Moshn',
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
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
        // Clamp accessibility text scaling so large-font users don't break our
        // fixed-height inputs/buttons. 0.9× protects mechanic dashboards with
        // many columns; 1.25× still honours user preference within reason.
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
