@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/presentation/pages/app_icon_page.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/bazaar_app_harness.dart';

/// A switch that logs each icon it is asked for.
final class _Switch implements IAppIconSwitch {
  final asked = <BazaarIcon>[];

  @override
  Future<void> choose(BazaarIcon icon) async => asked.add(icon);
}

Future<AppIconCubit> _pump(
  WidgetTester tester, {
  IAppIconSwitch iconSwitch = const NoAppIconSwitch(),
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
}) async {
  final cubit = AppIconCubit(iconSwitch: iconSwitch)..load();
  addTearDown(cubit.close);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const AppIconPage())],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(bazaarTestApp(router: router, appIcon: cubit, platform: platform, locale: locale));
  await tester.pumpAndSettle();
  return cubit;
}

Matcher _selected(bool selected) => isSemantics(isSelected: selected, isButton: true);

void main() {
  testWidgets('shows the six icons as pictures with their names, Dark the default and in use', (tester) async {
    await _pump(tester);

    for (final icon in BazaarIcon.values) {
      expect(find.byKey(appIconChoiceKey(icon)), findsOneWidget, reason: icon.name);
      expect(
        find.descendant(of: find.byKey(appIconChoiceKey(icon)), matching: find.image(AssetImage(icon.asset))),
        findsOneWidget,
        reason: icon.name,
      );
    }
    for (final name in ['Dark', 'Cream', 'Noir', 'Ink', 'Night gold', 'Night sea', 'Default']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.dark))), _selected(true));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.noir))), _selected(false));
  });

  testWidgets('stands the six in two rows of three', (tester) async {
    await _pump(tester);

    double top(BazaarIcon icon) => tester.getTopLeft(find.byKey(appIconChoiceKey(icon))).dy;
    expect({top(BazaarIcon.dark), top(BazaarIcon.cream), top(BazaarIcon.noir)}, hasLength(1));
    expect({top(BazaarIcon.ink), top(BazaarIcon.nightGold), top(BazaarIcon.nightSea)}, hasLength(1));
    expect(top(BazaarIcon.ink), greaterThan(top(BazaarIcon.dark)));
  });

  testWidgets('a tap makes that icon the app icon and marks it', (tester) async {
    final iconSwitch = _Switch();
    final cubit = await _pump(tester, iconSwitch: iconSwitch);
    iconSwitch.asked.clear();

    await tester.tap(find.byKey(appIconChoiceKey(BazaarIcon.nightSea)));
    await tester.pumpAndSettle();

    expect(cubit.state, const AppIconKnown(BazaarIcon.nightSea));
    expect(iconSwitch.asked, [BazaarIcon.nightSea]);
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.nightSea))), _selected(true));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.dark))), _selected(false));
  });

  testWidgets('says on Android that the icon changes once the app is left, and on iOS that the phone confirms it', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.textContaining('when you leave the app'), findsOneWidget);

    await _pump(tester, platform: TargetPlatform.iOS);
    expect(find.text('The phone confirms the new icon with a message.'), findsOneWidget);
  });

  testWidgets('names the icons in Turkish', (tester) async {
    await _pump(tester, locale: const Locale('tr'));

    expect(find.text('App ikonu'), findsOneWidget);
    expect(find.text('Gece denizi'), findsOneWidget);
    expect(find.text('Varsayılan'), findsOneWidget);
  });

  testWidgets('the page meets the platform guidelines', (tester) async {
    await _pump(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
