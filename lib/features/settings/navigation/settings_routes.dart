import 'package:ai_engineering_bazaar/features/settings/presentation/pages/settings_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class SettingsFeatureRoutes {
  /// The settings route; [openDevConsole] reaches the page's developer console entry (null hides it, Decision A6).
  static List<GoRoute> routes({required void Function(BuildContext context)? openDevConsole}) => [
    GoRoute(
      name: 'settings',
      path: ApplicationRoutesConstants.settings,
      pageBuilder: (context, state) => appTransitionPage(
        context: context,
        state: state,
        type: AppPageTransitionType.fade,
        child: SettingsPage(openDevConsole: openDevConsole),
      ),
    ),
  ];
}
