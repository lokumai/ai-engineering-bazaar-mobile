import 'dart:async';

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
    expect(cubit.state.icon, BazaarIcon.noir, reason: 'Noir, the default (the owner, 2026-11-15)');
  });

  test('load makes the kept icon current and names it to the phone again', () async {
    final iconSwitch = _Switch();
    final cubit = AppIconCubit(store: _Store(BazaarIcon.ink), iconSwitch: iconSwitch);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state, const AppIconKnown(BazaarIcon.ink));
    expect(iconSwitch.asked, [BazaarIcon.ink]);
  });

  test('an icon read at boot is current from the start, and load only names it to the phone', () async {
    final store = _Store(BazaarIcon.noir);
    final iconSwitch = _Switch();
    final cubit = AppIconCubit(store: store, iconSwitch: iconSwitch, initial: BazaarIcon.cream);
    addTearDown(cubit.close);

    expect(cubit.state, const AppIconKnown(BazaarIcon.cream));
    await cubit.load();

    expect(cubit.state, const AppIconKnown(BazaarIcon.cream));
    expect(iconSwitch.asked, [BazaarIcon.cream]);
  });

  test('with nothing kept, load settles on the default', () async {
    final cubit = AppIconCubit(store: _Store());
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state, const AppIconKnown(BazaarIcon.noir));
  });

  test('the icons stand in the order of the choice, Noir, the default, first (the owner, 2026-11-15)', () {
    expect(BazaarIcon.values, [
      BazaarIcon.noir,
      BazaarIcon.ink,
      BazaarIcon.nightGold,
      BazaarIcon.nightSea,
      BazaarIcon.dark,
      BazaarIcon.cream,
    ]);
    expect(BazaarIcon.defaultIcon, BazaarIcon.noir);
  });

  test('choose makes the icon current at once, keeps it and puts it on the home screen', () async {
    final store = _Store();
    final iconSwitch = _Switch();
    final cubit = AppIconCubit(store: store, iconSwitch: iconSwitch);
    addTearDown(cubit.close);

    final choosing = cubit.choose(BazaarIcon.noir);
    expect(cubit.state, const AppIconKnown(BazaarIcon.noir));
    await choosing;

    expect(store.kept, BazaarIcon.noir);
    expect(iconSwitch.asked, [BazaarIcon.noir]);
  });

  test('a choice made while the kept one is read is not overwritten by it', () async {
    final cubit = AppIconCubit(store: _Store(BazaarIcon.cream));
    addTearDown(cubit.close);

    final loading = cubit.load();
    await cubit.choose(BazaarIcon.nightGold);
    await loading;

    expect(cubit.state, const AppIconKnown(BazaarIcon.nightGold));
  });

  test('two quick choices reach the phone one after the other, in the order made', () async {
    final store = _Store();
    final iconSwitch = _Switch(gated: true);
    final cubit = AppIconCubit(store: store, iconSwitch: iconSwitch);
    addTearDown(cubit.close);

    final first = cubit.choose(BazaarIcon.noir);
    final second = cubit.choose(BazaarIcon.nightSea);
    await pumpEventQueue();
    expect(iconSwitch.asked, [BazaarIcon.noir], reason: 'the second waits for the first');

    iconSwitch.gates.first.complete();
    await pumpEventQueue();
    expect(iconSwitch.asked, [BazaarIcon.noir, BazaarIcon.nightSea]);
    iconSwitch.gates.last.complete();
    await Future.wait([first, second]);

    expect(store.writes, [BazaarIcon.noir, BazaarIcon.nightSea]);
    expect(cubit.state, const AppIconKnown(BazaarIcon.nightSea));
  });
}
