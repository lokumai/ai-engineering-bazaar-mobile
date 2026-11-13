import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';

/// [icon]'s name in the interface's language.
String appIconName(S s, BazaarIcon icon) => switch (icon) {
  BazaarIcon.dark => s.app_icon_dark,
  BazaarIcon.cream => s.app_icon_cream,
  BazaarIcon.noir => s.app_icon_noir,
  BazaarIcon.ink => s.app_icon_ink,
  BazaarIcon.nightGold => s.app_icon_night_gold,
  BazaarIcon.nightSea => s.app_icon_night_sea,
};
