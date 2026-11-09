import 'package:ai_engineering_bazaar/app/bootstrap/app_bootstrap.dart';
import 'package:ai_engineering_bazaar/app/bootstrap/app_bootstrap_config.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';

/// main entry point of local computer development
void main() async {
  await AppBootstrap.run(const AppBootstrapConfig(environment: Environment.dev));
}
