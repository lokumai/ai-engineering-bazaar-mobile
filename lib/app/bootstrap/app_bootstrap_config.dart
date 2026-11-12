import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';

class AppBootstrapConfig {
  const AppBootstrapConfig({required this.environment});

  final Environment environment;

  bool get isProduction => environment == Environment.prod;
}
