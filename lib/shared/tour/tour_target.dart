import 'package:flutter/widgets.dart';

/// The places the Apprentice's tour points at (plan 11.3), by name: each feature marks its own with a [TourTarget], and
/// the tour, a feature of its own, finds them here without importing the feature that drew them.
abstract final class TourSpots {
  /// Home's head: the Apprentice's corner with the day's card, or the card alone.
  static const homeHead = 'home.head';

  /// Home's Practice: Today's review and the glossary.
  static const homePractice = 'home.practice';

  /// The band over the navigation with the module to read now.
  static const band = 'shell.band';

  /// The bottom navigation.
  static const tabs = 'shell.tabs';

  /// The catalog's search field.
  static const catalogSearch = 'catalog.search';

  /// The catalog's levels and their modules.
  static const catalogLevels = 'catalog.levels';

  /// The Caravan's stage.
  static const caravanStage = 'caravan.stage';

  /// The Caravan's strip of stops under the stage.
  static const caravanStrip = 'caravan.strip';

  /// Practice's endless review, at the tab's head (plan 13.11; the owner, 2026-11-18).
  static const practiceToday = 'practice.today';

  /// Practice's first level of quizzes.
  static const quizLevel = 'quiz.level';

  /// Settings' reading choices: the track, the language and the look.
  static const settingsReading = 'settings.reading';

  /// Settings' Customize: the Apprentice's button, the app icon and its wardrobe.
  static const settingsCustomize = 'settings.customize';

  /// Settings' line on the website: how progress moves between the app and the site (plan 17.1).
  static const settingsWebsite = 'settings.website';

  /// Settings' way to the guide, where the tour is taken again.
  static const settingsGuide = 'settings.guide';

  /// The Apprentice's floating button: where it comes out of for the tour, and goes back into after it.
  static const assistant = 'shell.assistant';
}

/// Whether the Apprentice is out of its floating button, walking on the tour: the button is left empty meanwhile, so
/// the reader never sees two of it (the owner, 2026-11-16).
class TourRobotOut extends InheritedWidget {
  const TourRobotOut({super.key, required this.out, required super.child});

  final bool out;

  /// Whether it is out now; false with no tour over [context].
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TourRobotOut>()?.out ?? false;

  @override
  bool updateShouldNotify(TourRobotOut oldWidget) => oldWidget.out != out;
}

/// Marks [child] as the place [spot] names, for the tour to find it with [TourTarget.contextOf]. The one drawn last
/// is the one found; once it leaves the screen, the one drawn before it is found again (review 12, A1: a second shell
/// over a full-screen page took the tabs' spot, and once it went the first shell's was forgotten until it rebuilt).
class TourTarget extends StatefulWidget {
  const TourTarget({super.key, required this.spot, required this.child});

  /// One of [TourSpots].
  final String spot;
  final Widget child;

  /// The contexts marking each spot, the one drawn last at the end.
  static final Map<String, List<BuildContext>> _live = {};

  /// The context of the place [spot] names while it is on the screen; null otherwise.
  static BuildContext? contextOf(String spot) {
    for (final context in (_live[spot] ?? const <BuildContext>[]).reversed) {
      if (context.mounted) return context;
    }
    return null;
  }

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  @override
  void initState() {
    super.initState();
    _mark(widget.spot);
  }

  @override
  void didUpdateWidget(TourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spot != widget.spot) {
      _forget(oldWidget.spot);
      _mark(widget.spot);
    }
  }

  @override
  void dispose() {
    _forget(widget.spot);
    super.dispose();
  }

  void _mark(String spot) => (TourTarget._live[spot] ??= []).add(context);

  void _forget(String spot) {
    final marks = TourTarget._live[spot];
    if (marks == null) return;
    marks.removeWhere((mark) => identical(mark, context));
    if (marks.isEmpty) TourTarget._live.remove(spot);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
