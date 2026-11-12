import 'package:ai_engineering_bazaar/features/caravan/presentation/pages/caravan_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:go_router/go_router.dart';

class CaravanFeatureRoutes {
  /// The Caravan tab, in the middle of the bottom navigation (plan 3.1).
  static List<GoRoute> routes() => [
    GoRoute(
      name: 'caravan',
      path: BazaarPaths.caravan,
      pageBuilder: (context, state) => appTransitionPage(context: context, state: state, child: const CaravanPage()),
    ),
  ];
}
