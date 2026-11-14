import 'dart:async';
import 'dart:ui' show Color;

import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_cubit.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:flutter_test/flutter_test.dart';

/// A store that keeps the choice in memory, and logs each write.
final class _Store implements IAppIconStore {
  _Store([this.kept]);

  BazaarIcon? kept;
  final writes = <BazaarIcon>[];

  @override
  Future<BazaarIcon?> chosen() async => kept;

  @override
  Future<void> choose(BazaarIcon icon) async {
    writes.add(icon);
    kept = icon;
  }
}

/// A switch that logs each icon it is asked for, each waiting until the test lets it finish when [gated].
final class _Switch implements IAppIconSwitch {
  _Switch({this.gated = false});

  final bool gated;
  final asked = <BazaarIcon>[];
  final gates = <Completer<void>>[];

  @override
  Future<void> choose(BazaarIcon icon) async {
    asked.add(icon);
    if (!gated) return;
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
  }
}

void main() {
  test('is unread until the choice is read, showing the default meanwhile', () {
    final cubit = AppIconCubit();
    addTearDown(cubit.close);

    expect(cubit.state, const AppIconUnread());
    expect(cubit.state.icon, BazaarIcon.fezDark, reason: 'the fez on dark, the default');
  });

  test('load makes the kept icon current and names it to the phone again', () async {
    final iconSwitch = _Switch();
    final cubit = AppIconCubit(store: _Store(BazaarIcon.antennaCream), iconSwitch: iconSwitch);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state, const AppIconKnown(BazaarIcon.antennaCream));
    expect(iconSwitch.asked, [BazaarIcon.antennaCream]);
  });

  test('an icon read at boot is current from the start, and load only names it to the phone', () async {
    final store = _Store(BazaarIcon.fezDark);
    final iconSwitch = _Switch();
    final cubit = AppIconCubit(store: store, iconSwitch: iconSwitch, initial: BazaarIcon.fezCream);
    addTearDown(cubit.close);

    expect(cubit.state, const AppIconKnown(BazaarIcon.fezCream));
    await cubit.load();

    expect(cubit.state, const AppIconKnown(BazaarIcon.fezCream));
    expect(iconSwitch.asked, [BazaarIcon.fezCream]);
  });

  test('with nothing kept, load settles on the default', () async {
    final cubit = AppIconCubit(store: _Store());
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state, const AppIconKnown(BazaarIcon.fezDark));
  });

  test('every robot on dark and then on cream, in the order they unlock; the fez on dark the default (plan 9.10)', () {
    expect(BazaarIcon.values, [
      for (final robot in AppIconRobot.values)
        for (final ground in AppIconGround.values) BazaarIcon.of(robot, ground),
    ]);
    expect(BazaarIcon.defaultIcon, BazaarIcon.fezDark);
    expect(BazaarIcon.fezCream.ground, const Color(0xfffdfbf7));
    expect(BazaarIcon.crownDark.ground, const Color(0xff1d1f27));
  });

  test('choose makes the icon current at once, keeps it and puts it on the home screen', () async {
    final store = _Store();
    final iconSwitch = _Switch();
    final cubit = AppIconCubit(store: store, iconSwitch: iconSwitch);
    addTearDown(cubit.close);

    final choosing = cubit.choose(BazaarIcon.fezDark);
    expect(cubit.state, const AppIconKnown(BazaarIcon.fezDark));
    await choosing;

    expect(store.kept, BazaarIcon.fezDark);
    expect(iconSwitch.asked, [BazaarIcon.fezDark]);
  });

  test('a choice made while the kept one is read is not overwritten by it', () async {
    final cubit = AppIconCubit(store: _Store(BazaarIcon.fezCream));
    addTearDown(cubit.close);

    final loading = cubit.load();
    await cubit.choose(BazaarIcon.beanieDark);
    await loading;

    expect(cubit.state, const AppIconKnown(BazaarIcon.beanieDark));
  });

  test('two quick choices reach the phone one after the other, in the order made', () async {
    final store = _Store();
    final iconSwitch = _Switch(gated: true);
    final cubit = AppIconCubit(store: store, iconSwitch: iconSwitch);
    addTearDown(cubit.close);

    final first = cubit.choose(BazaarIcon.fezDark);
    final second = cubit.choose(BazaarIcon.tvCream);
    await pumpEventQueue();
    expect(iconSwitch.asked, [BazaarIcon.fezDark], reason: 'the second waits for the first');

    iconSwitch.gates.first.complete();
    await pumpEventQueue();
    expect(iconSwitch.asked, [BazaarIcon.fezDark, BazaarIcon.tvCream]);
    iconSwitch.gates.last.complete();
    await Future.wait([first, second]);

    expect(store.writes, [BazaarIcon.fezDark, BazaarIcon.tvCream]);
    expect(cubit.state, const AppIconKnown(BazaarIcon.tvCream));
  });
}
