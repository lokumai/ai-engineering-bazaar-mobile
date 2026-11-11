import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/pages/about_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:go_router/go_router.dart';

class AboutFeatureRoutes {
  /// The story of the Bazaar, opened from Settings.
  static List<GoRoute> routes() => [
    GoRoute(
      name: 'about',
      path: ApplicationRoutesConstants.about,
      pageBuilder: (context, state) => appTransitionPage(context: context, state: state, child: const AboutPage()),
    ),
  ];
}
