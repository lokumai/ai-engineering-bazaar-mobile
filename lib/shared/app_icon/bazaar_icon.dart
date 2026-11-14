import 'dart:ui' show Color;

/// The robots the app icons show (plan 9.10): the pocket model's robot, its head and hat as its round button draws
/// them, in one of its hats on its own screen, or in its fez on another of its heads. Each unlocks at the level of the
/// pocket model its wardrobe part unlocks at (`robot_outfit.dart`; `app_icon_robots_test` keeps the two in step), in
/// the order they unlock.
enum AppIconRobot {
  fez(0),
  antenna(0),
  beanie(2),
  dome(3, head: true),
  mortarboard(4),
  tv(5, head: true),
  turban(6),
  ears(7, head: true),
  wizard(8),
  topHat(10),
  visor(11, head: true),
  crown(12);

  const AppIconRobot(this.level, {this.head = false});

  /// The level of the pocket model that unlocks it.
  final int level;

  /// Whether it is one of the robot's heads, in its fez, rather than one of its hats on its own screen.
  final bool head;
}

/// The ground behind an app icon's robot: the app's two page colours.
enum AppIconGround {
  dark(_dark),
  cream(_cream);

  const AppIconGround(this.colour);

  final Color colour;
}

/// The app icons the reader can choose in Settings (the owner, 2026-11-14): each robot of [AppIconRobot] on each
/// ground of [AppIconGround], unlocked as the robot's wardrobe part is. [defaultIcon], the fez on the dark ground, is
/// the one a new install has. The opening plays in the chosen one's ground.
///
/// The native sides name each by its [name]: an `activity-alias` per icon in the Android manifest (`AppIconSwitch.kt`)
/// and an alternate icon per icon in the iOS asset catalog (`AppDelegate.swift`); `app_icon_choices_test` keeps the
/// three in step. `tool/render_app_icons.dart` draws every picture of them.
enum BazaarIcon {
  fezDark(AppIconRobot.fez, AppIconGround.dark),
  fezCream(AppIconRobot.fez, AppIconGround.cream),
  antennaDark(AppIconRobot.antenna, AppIconGround.dark),
  antennaCream(AppIconRobot.antenna, AppIconGround.cream),
  beanieDark(AppIconRobot.beanie, AppIconGround.dark),
  beanieCream(AppIconRobot.beanie, AppIconGround.cream),
  domeDark(AppIconRobot.dome, AppIconGround.dark),
  domeCream(AppIconRobot.dome, AppIconGround.cream),
  mortarboardDark(AppIconRobot.mortarboard, AppIconGround.dark),
  mortarboardCream(AppIconRobot.mortarboard, AppIconGround.cream),
  tvDark(AppIconRobot.tv, AppIconGround.dark),
  tvCream(AppIconRobot.tv, AppIconGround.cream),
  turbanDark(AppIconRobot.turban, AppIconGround.dark),
  turbanCream(AppIconRobot.turban, AppIconGround.cream),
  earsDark(AppIconRobot.ears, AppIconGround.dark),
  earsCream(AppIconRobot.ears, AppIconGround.cream),
  wizardDark(AppIconRobot.wizard, AppIconGround.dark),
  wizardCream(AppIconRobot.wizard, AppIconGround.cream),
  topHatDark(AppIconRobot.topHat, AppIconGround.dark),
  topHatCream(AppIconRobot.topHat, AppIconGround.cream),
  visorDark(AppIconRobot.visor, AppIconGround.dark),
  visorCream(AppIconRobot.visor, AppIconGround.cream),
  crownDark(AppIconRobot.crown, AppIconGround.dark),
  crownCream(AppIconRobot.crown, AppIconGround.cream);

  const BazaarIcon(this.robot, this.backdrop);

  /// The icon a new install has, until the reader chooses another: the home screen icon the stores and the system show.
  static const defaultIcon = fezDark;

  /// The robot it shows.
  final AppIconRobot robot;

  /// The ground behind it.
  final AppIconGround backdrop;

  /// The level of the pocket model that unlocks it.
  int get level => robot.level;

  /// The colour behind the robot, which the opening starts on.
  Color get ground => backdrop.colour;

  /// The colours of the opening's stripes, in the order teal, gold and brick, on this ground.
  (Color, Color, Color) get stripes => (_teal, _gold, _brick);

  /// The colour of the opening's tie.
  Color get tie => _brick;

  /// The icon of [robot] on [backdrop].
  static BazaarIcon of(AppIconRobot robot, AppIconGround backdrop) =>
      values.firstWhere((icon) => icon.robot == robot && icon.backdrop == backdrop);

  /// The icon's picture, as the choice shows it.
  String get asset => 'assets/app_icon/$name.png';
}

/// The colours of `mark.svg`, and the dark and cream page colours.
const _teal = Color(0xff2f8c86);
const _gold = Color(0xffc8a078);
const _brick = Color(0xffa0503c);
const _dark = Color(0xff1d1f27);
const _cream = Color(0xfffdfbf7);
