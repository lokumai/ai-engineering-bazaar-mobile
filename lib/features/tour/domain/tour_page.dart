import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';

/// A page the Apprentice's tour shows (plan 11.3): the first page of each tab, and the places on it it points at, in
/// order.
enum TourPage {
  home([TourSpots.homeHead, TourSpots.homeAfter, TourSpots.band, TourSpots.tabs]),
  catalog([TourSpots.catalogSearch, TourSpots.catalogLevels]),
  caravan([TourSpots.caravanStage, TourSpots.caravanStrip]),
  quiz([TourSpots.quizLevel]),
  settings([TourSpots.settingsReading, TourSpots.settingsGuide]);

  const TourPage(this.spots);

  /// The places it points at, in order; one not on the screen is passed over.
  final List<String> spots;

  /// The page at [location]; null for a page the tour does not show.
  static TourPage? at(String location) => switch (location) {
    BazaarPaths.home => home,
    BazaarPaths.catalogEngineers || BazaarPaths.catalogEveryone => catalog,
    BazaarPaths.caravan => caravan,
    BazaarPaths.quizzes => quiz,
    BazaarPaths.settings => settings,
    _ => null,
  };
}
