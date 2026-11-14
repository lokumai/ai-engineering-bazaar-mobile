import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_welcome_step.dart';
import 'package:flutter/material.dart';
import 'package:ai_engineering_bazaar/app/app_gate.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/app/di/app_scope.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_gate.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/robot_stage.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_sting.dart';
import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_choice_cubit.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({super.key, this.dependencies = const AppDependencies(), this.appIcon});

  final AppDependencies dependencies;

  /// The app icon the boot read, so the opening starts in its colours; null when it was not read.
  final BazaarIcon? appIcon;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = AppRouterFactory(crashReports: widget.dependencies.appConfig.sentryDsn != null)
      .create();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      appIcon: widget.appIcon,
      dependencies: widget.dependencies,
      // The interface follows the chosen language (plan 1Q); Persian lays it out right to left.
      child: BlocBuilder<ThemeChoiceCubit, ThemeMode>(
        builder: (context, themeMode) => BlocBuilder<LanguageCubit, String>(
          builder: (context, language) => MaterialApp.router(
            locale: Locale(language),
            // The name the task switcher shows.
            onGenerateTitle: (context) => S.of(context).app_title,
            theme: bazaarTheme(brightness: Brightness.light, platform: defaultTargetPlatform),
            darkTheme: bazaarTheme(brightness: Brightness.dark, platform: defaultTargetPlatform),
            themeMode: themeMode,
            themeAnimationDuration: Duration.zero,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            routerConfig: _router,
            // The router shows only once the content and the record are ready (spec 3.7), behind Welcome on the first
            // launch (plan Phase 1I).
            // The robot's opening plays over the app as it opens (plan 1Y, 9.10).
            builder: (context, child) => WelcomeSting(
              // The robot in what the reader dressed it in greets them (plan 9.10).
              robot: (onDone) => RobotStage(hello: true, onHello: onDone),
              child: AppGate(
                child: WelcomeGate(
                  // The second step is the story of the Bazaar, a feature of its own (plan 3.5).
                  story: (onDone) => AboutWelcomeStep(onDone: onDone),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
