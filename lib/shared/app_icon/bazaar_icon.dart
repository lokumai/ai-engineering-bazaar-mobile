import 'dart:ui' show Color;

/// The app icons the reader can choose in Settings (the owner, 2026-11-14): the striped secret agent of
/// `assets/brand/app_icon/mark.svg` in six colourings, [defaultIcon] (Noir) the one a new install has. The opening
/// plays in the chosen one's colours. The order is the choice's: Noir first, then Ink, Night gold, Night sea, Dark and
/// Cream (the owner, 2026-11-15).
///
/// The native sides name each by its [name]: an `activity-alias` per icon in the Android manifest (`AppIconSwitch.kt`)
/// and an alternate icon per icon in the iOS asset catalog (`AppDelegate.swift`); `app_icon_choices_test` keeps the
/// three in step.
enum BazaarIcon {
  noir(ground: _dark, stripes: (_cream, _cream, _cream), tie: _brick),
  ink(ground: _cream, stripes: (_dark, _dark, _dark), tie: _brick),
  nightGold(ground: _dark, stripes: (_gold, _gold, _gold), tie: _brick),
  nightSea(ground: Color(0xff16302f), stripes: (_teal, _gold, _cream), tie: _cream),
  dark(ground: _dark, stripes: (_teal, _gold, _brick), tie: _brick),
  cream(ground: _cream, stripes: (_teal, _gold, _brick), tie: _brick);

  const BazaarIcon({required this.ground, required this.stripes, required this.tie});

  /// The icon a new install has, until the reader chooses another: the home screen icon the stores and the system show.
  static const defaultIcon = noir;

  /// The colour behind the agent.
  final Color ground;

  /// The colours of the stripes, in the order Dark's teal, gold and brick take.
  final (Color, Color, Color) stripes;

  /// The colour of the tie.
  final Color tie;

  /// The icon's picture, as the choice shows it.
  String get asset => 'assets/app_icon/$name.png';
}

/// The colours of `mark.svg`, and the dark and cream page colours.
const _teal = Color(0xff2f8c86);
const _gold = Color(0xffc8a078);
const _brick = Color(0xffa0503c);
const _dark = Color(0xff1d1f27);
const _cream = Color(0xfffdfbf7);
