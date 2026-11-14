import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pages/robot_wardrobe_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:go_router/go_router.dart';

class PocketModelFeatureRoutes {
  /// The robot's wardrobe, from Settings' Customize (plan 9.9).
  static List<GoRoute> routes() => [
    GoRoute(
      name: 'robot',
      path: ApplicationRoutesConstants.robot,
      pageBuilder: (context, state) =>
          appTransitionPage(context: context, state: state, child: const RobotWardrobePage()),
    ),
  ];
}
