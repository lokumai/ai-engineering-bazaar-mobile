import 'package:ai_engineering_bazaar/features/transfer/presentation/transfer_page.dart';
import 'package:ai_engineering_bazaar/shared/design_system/components/app_page_transition.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:go_router/go_router.dart';

class TransferFeatureRoutes {
  /// A progress transfer link, full screen over the shell (plan 17.1). The app opens it with the link's payload as the
  /// route's extra; without one the page says the link cannot be read.
  static List<GoRoute> routes() => [
    GoRoute(
      name: 'transfer',
      path: BazaarPaths.transfer,
      pageBuilder: (context, state) => appTransitionPage(
        context: context,
        state: state,
        child: TransferPage(payload: state.extra is String ? state.extra! as String : ''),
      ),
    ),
  ];
}
