import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static String appVersion = "1.0.0";
  static String appBuildNumber = "1";

  /// Reads the version and build number from the phone. A read that fails keeps the defaults, so the app still starts
  /// rather than stay on the launch screen (review 4, finding 9).
  static Future<void> initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      appBuildNumber = info.buildNumber;
    } on Object {
      return;
    }
  }
}
