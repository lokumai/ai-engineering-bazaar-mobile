@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/data_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/accessibility.dart';
import '../data_host.dart';

const _actions = ['Back up to a file', 'Restore from a file', 'Reset'];

Finder _button(String label) => find.widgetWithText(TextButton, label);

void main() {
  Future<DataBloc> pumpLine(WidgetTester tester, [DataState state = const DataState()]) async {
    final (bloc, _) = dataBlocAt(state);
    await pumpDataHost(tester, const DataLine(), data: bloc);
    return bloc;
  }

  testWidgets('the data line shows its sentence and three actions', (tester) async {
    await pumpLine(tester);

    expect(find.textContaining('Your progress is saved on this device only.'), findsOneWidget);
    for (final label in _actions) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Undo'), findsNothing);
    expect(
      tester.getTopLeft(_button('Back up to a file')).dx,
      lessThan(tester.getTopLeft(_button('Restore from a file')).dx),
    );
    expect(tester.getTopLeft(_button('Restore from a file')).dx, lessThan(tester.getTopLeft(_button('Reset')).dx));
  });

  testWidgets('Reset is drawn in onSurface', (tester) async {
    await pumpLine(tester);
    final theme = Theme.of(tester.element(find.byType(DataLine)));

    final button = tester.widget<TextButton>(_button('Reset'));
    expect(button.style!.foregroundColor!.resolve(<WidgetState>{}), theme.colorScheme.onSurface);
  });

  testWidgets('the actions add their events', (tester) async {
    final bloc = await pumpLine(tester, const DataState(reset: ResetCounting(5)));

    await tester.tap(find.text('Back up to a file'));
    await tester.tap(find.text('Restore from a file'));
    await tester.tap(find.text('Undo'));
    final events = verify(() => bloc.add(captureAny())).captured;
    expect(events, [isA<BackupRequested>(), isA<RestoreRequested>(), isA<UndoRequested>()]);
  });

  testWidgets('every action is off while a flow runs', (tester) async {
    for (final busy in [DataBusy.backingUp, DataBusy.restoring, DataBusy.erasing, DataBusy.savingQuarantine]) {
      await pumpLine(tester, DataState(busy: busy));
      for (final label in _actions) {
        expect(tester.widget<TextButton>(_button(label)).onPressed, isNull, reason: '$label while $busy');
      }
    }
    await pumpLine(tester);
    for (final label in _actions) {
      expect(tester.widget<TextButton>(_button(label)).onPressed, isNotNull, reason: label);
    }
  });

  testWidgets('the status lines are a live region', (tester) async {
    await pumpLine(tester, const DataState(backup: BackedUp('2026-03-15')));

    expect(
      find.ancestor(
        of: find.text('Backed up 2026-03-15'),
        matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.liveRegion == true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('each outcome prints its line', (tester) async {
    await pumpLine(tester, const DataState(backup: BackedUp('2026-03-15')));
    expect(find.text('Backed up 2026-03-15'), findsOneWidget);

    await pumpLine(tester, const DataState(backup: BackupNotWritten()));
    expect(find.text('The backup file could not be written. Nothing was marked as backed up.'), findsOneWidget);

    const restoreLines = {
      RestoreOutcome.restored: 'Restored from the file.',
      RestoreOutcome.empty: 'Nothing was changed. That file holds no progress; only a backup file does.',
      RestoreOutcome.newer:
          'That file was written by a newer version of the app or the website. Update the app, then restore it again.',
      RestoreOutcome.malformed: 'That file is not a backup the app or the website wrote. Nothing was changed.',
      RestoreOutcome.unreadable: 'That file could not be opened.',
    };
    for (final MapEntry(key: outcome, value: line) in restoreLines.entries) {
      await pumpLine(tester, DataState(restore: outcome));
      expect(find.text(line), findsOneWidget, reason: '$outcome');
    }

    await pumpLine(tester, const DataState(reset: ResetCounting(3)));
    expect(find.text('Reset. You can undo it for 3 seconds.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await pumpLine(tester, const DataState(reset: ResetCounting(1)));
    expect(find.text('Reset. You can undo it for 1 second.'), findsOneWidget);

    await pumpLine(tester, const DataState(reset: ResetClosed()));
    expect(find.text('Reset. The time to undo it has passed.'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);

    await pumpLine(tester, const DataState(reset: ResetNotFinished()));
    expect(
      find.text(
        'The reset did not finish: the app could not delete its files. The progress on this device is unchanged.',
      ),
      findsOneWidget,
    );
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('the lines stand together in the order backup, restore, reset', (tester) async {
    await pumpLine(
      tester,
      const DataState(backup: BackedUp('2026-03-15'), restore: RestoreOutcome.restored, reset: ResetClosed()),
    );

    final backup = tester.getTopLeft(find.text('Backed up 2026-03-15')).dy;
    final restore = tester.getTopLeft(find.text('Restored from the file.')).dy;
    final reset = tester.getTopLeft(find.text('Reset. The time to undo it has passed.')).dy;
    expect(backup, lessThan(restore));
    expect(restore, lessThan(reset));
  });

  testWidgets('no status line, no live region', (tester) async {
    await pumpLine(tester);

    expect(
      find.descendant(
        of: find.byType(DataLine),
        matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.liveRegion == true),
      ),
      findsNothing,
    );
  });

  testWidgets('Reset opens the erase dialog and adds ResetConfirmed only after the word', (tester) async {
    final bloc = await pumpLine(tester);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Erase all progress on this device?'), findsOneWidget);
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any()));

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ERASE');
    await tester.pump();
    await tester.tap(find.text('Erase all data'));
    await tester.pumpAndSettle();
    expect(find.text('Erase all progress on this device?'), findsNothing);
    expect(verify(() => bloc.add(captureAny())).captured, [isA<ResetConfirmed>()]);
  });

  testWidgets('text scale 2.0', (tester) async {
    final (bloc, _) = dataBlocAt(const DataState(reset: ResetCounting(5), backup: BackedUp('2026-03-15')));
    await pumpAtTextScale(tester, dataHost(const DataLine(), data: bloc), scale: 2.0);

    expect(tester.takeException(), isNull);
    for (final label in [..._actions, 'Undo']) {
      await tester.ensureVisible(_button(label));
      await tester.pump();
      expectHittable(tester, _button(label));
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    final (bloc, _) = dataBlocAt(const DataState(reset: ResetCounting(5), restore: RestoreOutcome.restored));
    await pumpDataHost(tester, const DataLine(), data: bloc, platform: defaultTargetPlatform);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
