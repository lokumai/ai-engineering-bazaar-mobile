import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/app/app_gate.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/app/di/app_scope.dart';
import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({super.key, this.dependencies = const AppDependencies()});

  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = const AppRouterFactory().create();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: widget.dependencies,
      child: MaterialApp.router(
        // The name the task switcher shows.
        onGenerateTitle: (context) => S.of(context).app_title,
        theme: bazaarTheme(brightness: Brightness.light, platform: defaultTargetPlatform),
        darkTheme: bazaarTheme(brightness: Brightness.dark, platform: defaultTargetPlatform),
        themeMode: ThemeMode.system,
        themeAnimationDuration: Duration.zero,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: _router,
        // The router shows only once the content and the record are ready (spec 3.7).
        builder: (context, child) => AppGate(child: child!),
      ),
    );
  }
}
