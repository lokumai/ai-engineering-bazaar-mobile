@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/erase_dialog.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/accessibility.dart';
import '../data_host.dart';

const _at = '2026-03-15T10:00:00.000Z';

RecordData _completed(List<String> keys) =>
    keys.fold(RecordData.empty, (record, key) => signOff(record, key, null, _at));

/// Lets the armed button's label colour finish its animation from the disabled colour (Material animates its text
/// style for 200 ms from the frame that rebuilt it).
Future<void> armed(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> keep(WidgetTester tester) async {
  await tester.tap(find.text('Keep my data'));
  await tester.pumpAndSettle();
}

Finder _erase() => find.widgetWithText(OutlinedButton, 'Erase all data');

void main() {
  /// Opens the dialog over a host of [data] and [record], and hands back its answer once it closes.
  Future<Future<bool>> open(
    WidgetTester tester, {
    required DataBloc data,
    RecordData record = RecordData.empty,
    TargetPlatform platform = TargetPlatform.android,
    Locale locale = const Locale('en'),
  }) async {
    await pumpDataHost(
      tester,
      const SizedBox.shrink(),
      data: data,
      record: recordBlocAt(record: record),
      platform: platform,
      locale: locale,
    );
    final answer = showEraseDialog(hostContext(tester));
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('the erase button arms on the word, trimmed and in any case', (tester) async {
    final (bloc, _) = dataBlocAt();
    await open(tester, data: bloc);

    for (final (typed, armed) in [('ERAS', false), ('erase ', true), (' Erase ', true), ('E R A S E', false)]) {
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump();
      expect(tester.widget<OutlinedButton>(_erase()).onPressed != null, armed, reason: "'$typed'");
    }
  });

  testWidgets('in Turkish the dialog asks for SİL, and takes it typed on any keyboard, and ERASE (owner, 2026-11-13)', (
    tester,
  ) async {
    final (bloc, _) = dataBlocAt();
    await open(tester, data: bloc, locale: const Locale('tr'));
    expect(find.text('Onaylamak için SİL yaz'), findsOneWidget);

    final erase = find.widgetWithText(OutlinedButton, 'Bütün verileri sil');
    for (final (typed, armed) in [('si', false), ('sil', true), ('SIL', true), ('erase', true), ('silin', false)]) {
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump();
      expect(tester.widget<OutlinedButton>(erase).onPressed != null, armed, reason: "'$typed'");
    }
  });

  testWidgets('the typed word is gone when the dialog closes', (tester) async {
    final (bloc, _) = dataBlocAt();
    final first = await open(tester, data: bloc);
    await tester.enterText(find.byType(TextField), 'ERASE');
    await armed(tester);
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();
    expect(await first, isFalse);

    showEraseDialog(hostContext(tester));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(tester.widget<OutlinedButton>(_erase()).onPressed, isNull);
  });

  testWidgets('the erase dialog shows the tally, the scope and the backup statement', (tester) async {
    final (bloc, _) = dataBlocAt();
    await open(tester, data: bloc, record: _completed(['alpha/first', 'alpha/second']));
    expect(find.text('2 module states'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);
    expect(find.text('Erase all progress on this device?'), findsOneWidget);
    expect(
      find.text(
        'This removes the record from this device, including the copy set aside from a version of the app this one '
        'could not read.',
      ),
      findsOneWidget,
    );
    expect(find.text('A device backup may still hold an earlier copy of your progress.'), findsOneWidget);
    expect(find.text('Type ERASE to confirm'), findsOneWidget);
    for (final word in ['Cancel', 'Yes', 'No']) {
      expect(find.text(word), findsNothing);
    }

    await keep(tester);

    await open(tester, data: bloc, record: _completed(['alpha/first']));
    expect(find.text('1 module state'), findsOneWidget);
    await keep(tester);

    await open(tester, data: bloc);
    expect(find.text('NOTHING RECORDED ON THIS DEVICE'), findsOneWidget);
  });

  testWidgets('erase confirms, keeps or backs up', (tester) async {
    final (bloc, states) = dataBlocAt();
    final kept = await open(tester, data: bloc);
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();
    expect(await kept, isFalse);
    expect(find.text('Erase all progress on this device?'), findsNothing);

    final backedUp = await open(tester, data: bloc);
    await tester.tap(find.text('Back up'));
    await tester.pump();
    expect(verify(() => bloc.add(captureAny())).captured, [isA<BackupRequested>()]);
    expect(find.text('Erase all progress on this device?'), findsOneWidget);
    states.add(const DataState(backup: BackedUp('2026-03-15')));
    await tester.pump();
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Backed up 2026-03-15')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ERASE');
    await armed(tester);
    await tester.tap(_erase());
    await tester.pumpAndSettle();
    expect(await backedUp, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Back up is off while a flow runs', (tester) async {
    final (bloc, _) = dataBlocAt(const DataState(busy: DataBusy.backingUp));
    await open(tester, data: bloc);

    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Back up')).onPressed, isNull);
  });

  testWidgets('Erase all data has a fault edge and an onSurface label', (tester) async {
    final (bloc, _) = dataBlocAt();
    await open(tester, data: bloc);
    await tester.enterText(find.byType(TextField), 'ERASE');
    await armed(tester);

    final context = tester.element(_erase());
    final style = tester.widget<OutlinedButton>(_erase()).style!;
    expect(style.foregroundColor!.resolve(<WidgetState>{}), Theme.of(context).colorScheme.onSurface);
    expect(style.side!.resolve(<WidgetState>{})!.color, context.bazaarColors.fault);
    final icon = tester.widget<Icon>(find.descendant(of: _erase(), matching: find.byType(Icon)));
    expect(icon.color, context.bazaarColors.fault);
  });

  testWidgets('text scale 2.0', (tester) async {
    final (bloc, _) = dataBlocAt();
    await pumpAtTextScale(tester, dataHost(const SizedBox.shrink(), data: bloc, record: recordBlocAt()), scale: 2.0);
    showEraseDialog(hostContext(tester));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ERASE');
    await armed(tester);

    expect(tester.takeException(), isNull);
    for (final button in [_erase(), find.text('Keep my data'), find.text('Back up')]) {
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expectHittable(tester, button);
    }
  });

  testWidgets('meets the platform guidelines', variant: bazaarPlatforms, (tester) async {
    final (bloc, _) = dataBlocAt();
    await open(tester, data: bloc, record: _completed(['alpha/first']), platform: defaultTargetPlatform);
    await tester.enterText(find.byType(TextField), 'ERASE');
    await armed(tester);

    await expectPlatformGuidelines(tester, platform: defaultTargetPlatform);
  });
}
