/// Whether the shell is moving to another tab: the pages that come in and go out with the move draw no transition, so
/// one tab's page never shows through another's (the owner, 2026-11-12), as tabs change at once on iOS and Android. The
/// shell marks the move before it tells the router and ends it once the new pages are drawn.
abstract final class TabSwitch {
  static bool _active = false;

  /// Whether a move to another tab is under way.
  static bool get active => _active;

  static void begin() => _active = true;

  static void end() => _active = false;
}
