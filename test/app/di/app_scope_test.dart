import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/app/di/app_scope.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('provides the AppConfig of its dependencies', (tester) async {
    late AppConfig config;
    await tester.pumpWidget(
      AppScope(
        dependencies: const AppDependencies(appConfig: AppConfig.test()),
        child: Builder(
          builder: (context) {
            config = context.read<AppConfig>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(config.environment, Environment.test);
  });
}
