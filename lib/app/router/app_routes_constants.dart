/// Routes for the application
///
/// This class contains all the routes used in the application.
class ApplicationRoutesConstants {
  // Settings routes
  static const settings = '/settings';

  /// Settings' privacy and legal notes (plan 3.4).
  static const privacyLegal = '/settings/privacy';

  /// Report a problem, from Settings, in a build that sends crash reports.
  static const feedback = '/settings/feedback';

  /// The story of the Bazaar, from Settings (web D115, D125).
  static const about = '/settings/about';

  /// How the bazaar works, from Settings; Welcome's guide before About took its place.
  static const guide = '/settings/guide';

  // Error routes
  static const notFound = '/not-found';
}
