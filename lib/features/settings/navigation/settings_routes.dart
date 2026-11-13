import 'package:ai_engineering_bazaar/features/settings/presentation/pages/privacy_legal_page.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class SettingsFeatureRoutes {
  /// The settings route and its privacy and legal page; [openDevConsole] reaches the page's developer console entry
  /// (null hides it, Decision A6), and [crashReports] says whether this build sends crash reports (plan 3.4).
  static List<GoRoute> routes({
    required void Function(BuildContext context)? openDevConsole,
    required bool crashReports,
  }) => [
    GoRoute(
      name: 'settings',
      path: ApplicationRoutesConstants.settings,
      pageBuilder: (context, state) => appTransitionPage(
        context: context,
        state: state,
        child: SettingsPage(openDevConsole: openDevConsole),
      ),
    ),
    GoRoute(
      name: 'privacyLegal',
      path: ApplicationRoutesConstants.privacyLegal,
      pageBuilder: (context, state) => appTransitionPage(
        context: context,
        state: state,
        child: PrivacyLegalPage(crashReports: crashReports),
      ),
    ),
  ];
}
