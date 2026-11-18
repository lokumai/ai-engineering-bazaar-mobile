import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';

/// A page the Apprentice's tour shows (plan 11.3): the first page of each tab, and the places on it it points at, in
/// order.
enum TourPage {
  home([TourSpots.homeHead, TourSpots.homeAfter, TourSpots.band, TourSpots.tabs]),
  catalog([TourSpots.catalogSearch, TourSpots.catalogLevels]),
  caravan([TourSpots.caravanStage, TourSpots.caravanStrip]),

  /// Practice (plan 13.11): its head, then the quizzes by level. Named anew from the Quiz tab's page, so a reader who
  /// saw that one is shown Practice too.
  practice([TourSpots.practiceToday, TourSpots.quizLevel]),
  settings([TourSpots.settingsReading, TourSpots.settingsCustomize, TourSpots.settingsGuide]);

  const TourPage(this.spots);

  /// The places it points at, in order; one not on the screen is passed over.
  final List<String> spots;

  /// The page at [location]; null for a page the tour does not show.
  static TourPage? at(String location) => switch (location) {
    BazaarPaths.home => home,
    BazaarPaths.catalogEngineers || BazaarPaths.catalogEveryone => catalog,
    BazaarPaths.caravan => caravan,
    BazaarPaths.practice => practice,
    BazaarPaths.settings => settings,
    _ => null,
  };
}
