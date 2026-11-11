import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/features/guide/presentation/pages/guide_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:go_router/go_router.dart';

class GuideFeatureRoutes {
  /// How the bazaar works, opened from Settings.
  static List<GoRoute> routes() => [
    GoRoute(
      name: 'guide',
      path: ApplicationRoutesConstants.guide,
      pageBuilder: (context, state) => appTransitionPage(context: context, state: state, child: const GuidePage()),
    ),
  ];
}
