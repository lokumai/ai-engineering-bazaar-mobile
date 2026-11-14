@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/presentation/pages/app_icon_page.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/presentation/app_icon_choices.dart';
import 'package:ai_engineering_bazaar/shared/robot_level/robot_level_cubit.dart';
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
  int level = 0,
  BazaarIcon? initial,
}) async {
  tester.view.physicalSize = const Size(393, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final cubit = AppIconCubit(iconSwitch: iconSwitch, initial: initial)..load();
  addTearDown(cubit.close);
  final robotLevel = RobotLevelCubit()..reached(level);
  // The provider the test app makes of it closes it.
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const AppIconPage())],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    bazaarTestApp(router: router, appIcon: cubit, robotLevel: robotLevel, platform: platform, locale: locale),
  );
  await tester.pumpAndSettle();
  return cubit;
}

Matcher _selected(bool selected) => isSemantics(isSelected: selected, isButton: true);

Finder _picture(AppIconRobot robot, BazaarIcon icon) =>
    find.descendant(of: find.byKey(appIconChoiceKey(robot)), matching: find.image(AssetImage(icon.asset)));

void main() {
  testWidgets('the ground above, then every robot of the wardrobe on it; the fez on dark the default and in use', (
    tester,
  ) async {
    await _pump(tester, level: 20);

    final ground = tester.getRect(find.byKey(appIconGroundKey(AppIconGround.dark)));
    for (final robot in AppIconRobot.values) {
      expect(_picture(robot, BazaarIcon.of(robot, AppIconGround.dark)), findsOneWidget, reason: robot.name);
      expect(tester.getTopLeft(find.byKey(appIconChoiceKey(robot))).dy, greaterThan(ground.bottom));
    }
    expect(tester.getSemantics(find.byKey(appIconGroundKey(AppIconGround.dark))), isSemantics(isSelected: true));
    // No names under the pictures (the owner, 2026-11-14); a screen reader hears them.
    expect(find.text('Fez'), findsNothing);
    expect(
      tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.fez))),
      isSemantics(label: 'Fez, Dark, Default'),
    );
    expect(
      tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.wizard))),
      isSemantics(label: "Wizard's hat, Dark"),
    );
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.fez))), _selected(true));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.wizard))), _selected(false));
  });

  testWidgets('choosing cream puts every robot on cream, and the icon in use with them', (tester) async {
    final iconSwitch = _Switch();
    final cubit = await _pump(tester, iconSwitch: iconSwitch, level: 20, initial: BazaarIcon.tvDark);
    iconSwitch.asked.clear();

    await tester.tap(find.byKey(appIconGroundKey(AppIconGround.cream)));
    await tester.pumpAndSettle();

    expect(cubit.state.icon, BazaarIcon.tvCream);
    expect(iconSwitch.asked, [BazaarIcon.tvCream]);
    for (final robot in AppIconRobot.values) {
      expect(_picture(robot, BazaarIcon.of(robot, AppIconGround.cream)), findsOneWidget, reason: robot.name);
    }
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.tv))), _selected(true));

    await tester.tap(find.byKey(appIconGroundKey(AppIconGround.dark)));
    await tester.pumpAndSettle();
    expect(cubit.state.icon, BazaarIcon.tvDark);
  });

  testWidgets('a tap on a robot makes it the app icon on the ground chosen, and marks it', (tester) async {
    final iconSwitch = _Switch();
    final cubit = await _pump(tester, iconSwitch: iconSwitch, level: 20, initial: BazaarIcon.fezCream);
    iconSwitch.asked.clear();

    await tester.tap(find.byKey(appIconChoiceKey(AppIconRobot.crown)));
    await tester.pumpAndSettle();

    expect(cubit.state, const AppIconKnown(BazaarIcon.crownCream));
    expect(iconSwitch.asked, [BazaarIcon.crownCream]);
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.crown))), _selected(true));
    expect(tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.fez))), _selected(false));
  });

  testWidgets('a robot the pocket model has not unlocked in its wardrobe is locked, with its level', (tester) async {
    final cubit = await _pump(tester, level: 2);

    expect(
      tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.dome))),
      isSemantics(label: 'Round head, Dark, unlocks at level 3'),
    );
    expect(
      find.descendant(of: find.byKey(appIconChoiceKey(AppIconRobot.dome)), matching: find.text('Level 3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(appIconChoiceKey(AppIconRobot.beanie)), matching: find.byIcon(Icons.lock_rounded)),
      findsNothing,
      reason: 'the beanie unlocks at level 2',
    );
    await tester.tap(find.byKey(appIconChoiceKey(AppIconRobot.dome)));
    await tester.pumpAndSettle();
    expect(cubit.state.icon, BazaarIcon.fezDark, reason: 'a locked icon cannot be chosen');

    await tester.tap(find.byKey(appIconChoiceKey(AppIconRobot.beanie)));
    await tester.pumpAndSettle();
    expect(cubit.state.icon, BazaarIcon.beanieDark);
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
    await _pump(tester, locale: const Locale('tr'), level: 20);

    expect(find.text('App ikonu'), findsOneWidget);
    expect(find.text('Krem'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(appIconChoiceKey(AppIconRobot.fez))),
      isSemantics(label: 'Fes, Koyu, Varsayılan'),
    );
  });

  testWidgets('the page meets the platform guidelines', (tester) async {
    await _pump(tester, platform: defaultTargetPlatform, level: 4);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  }, variant: bazaarPlatforms);
}
