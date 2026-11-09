import 'package:ai_engineering_bazaar/features/settings/navigation/settings_routes.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings feature exposes expected route', () {
    expect(SettingsFeatureRoutes.routes, hasLength(1));
    expect(SettingsFeatureRoutes.routes.single.path, ApplicationRoutesConstants.settings);
    expect(SettingsFeatureRoutes.routes.single.name, 'settings');
  });
}
