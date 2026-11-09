import 'package:flutter/services.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';

class AppBootstrapConfig {
  const AppBootstrapConfig({
    required this.environment,
    this.preferredOrientations = const [DeviceOrientation.portraitUp],
  });

  final Environment environment;
  final List<DeviceOrientation> preferredOrientations;

  bool get isProduction => environment == Environment.prod;
}
