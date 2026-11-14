@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/presentation/pages/app_icon_page.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/presentation/app_icon_choices.dart';
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
  testWidgets('shows the six icons as pictures, named only to a screen reader, Noir the default and in use', (
    tester,
  ) async {
    await _pump(tester);

    for (final icon in BazaarIcon.values) {
      expect(find.byKey(appIconChoiceKey(icon)), findsOneWidget, reason: icon.name);
      expect(
        find.descendant(of: find.byKey(appIconChoiceKey(icon)), matching: find.image(AssetImage(icon.asset))),
        findsOneWidget,
        reason: icon.name,
      );
    }
    // No names under the pictures (the owner, 2026-11-14); a screen reader hears them.
    for (final name in ['Dark', 'Cream', 'Noir', 'Ink', 'Night gold', 'Night sea', 'Default']) {
      expect(find.text(name), findsNothing, reason: name);
    }
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.noir))), isSemantics(label: 'Noir, Default'));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.dark))), isSemantics(label: 'Dark'));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.noir))), _selected(true));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.dark))), _selected(false));
  });

  testWidgets('stands the six in two rows of three: Noir, Ink, Night gold; Night sea, Dark, Cream', (tester) async {
    await _pump(tester);

    Offset at(BazaarIcon icon) => tester.getTopLeft(find.byKey(appIconChoiceKey(icon)));
    final rows = [
      [BazaarIcon.noir, BazaarIcon.ink, BazaarIcon.nightGold],
      [BazaarIcon.nightSea, BazaarIcon.dark, BazaarIcon.cream],
    ];
    for (final row in rows) {
      expect({for (final icon in row) at(icon).dy}, hasLength(1), reason: '$row');
      expect(at(row[0]).dx, lessThan(at(row[1]).dx));
      expect(at(row[1]).dx, lessThan(at(row[2]).dx));
    }
    expect(at(BazaarIcon.nightSea).dy, greaterThan(at(BazaarIcon.noir).dy));
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
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.noir))), _selected(false));
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
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.nightSea))), isSemantics(label: 'Gece denizi'));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(BazaarIcon.noir))), isSemantics(label: 'Noir, Varsayılan'));
  });

  testWidgets('the page meets the platform guidelines', (tester) async {
    await _pump(tester, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
