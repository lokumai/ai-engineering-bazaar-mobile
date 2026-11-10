import 'dart:async';

import 'package:ai_engineering_bazaar/features/settings/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/envelope.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';

/// A [MockDataBloc] that starts at [initial] and then takes each state added to the returned controller.
(MockDataBloc, StreamController<DataState>) dataBlocAt([DataState initial = const DataState()]) {
  final bloc = MockDataBloc();
  final states = StreamController<DataState>.broadcast();
  addTearDown(states.close);
  whenListen(bloc, states.stream, initialState: initial);
  return (bloc, states);
}

/// A [MockRecordBloc] at [RecordReady] over [record], with the quarantine fields given.
MockRecordBloc recordBlocAt({
  RecordData record = RecordData.empty,
  QuarantineReason? quarantine,
  bool quarantineKept = false,
  WriteState writeState = const WriteSaved(),
}) {
  final bloc = MockRecordBloc();
  whenListen(
    bloc,
    const Stream<RecordState>.empty(),
    initialState: RecordReady(
      record: record,
      writeState: writeState,
      quarantine: quarantine,
      quarantineKept: quarantineKept,
      launchReadFailed: false,
      undo: null,
    ),
  );
  return bloc;
}

/// Pumps [child] in a scrolling Scaffold under the Bazaar theme, below providers of [data] and [record] (a ready empty
/// record when null).
Future<void> pumpDataHost(
  WidgetTester tester,
  Widget child, {
  required DataBloc data,
  RecordBloc? record,
  Brightness brightness = Brightness.light,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  await tester.pumpWidget(dataHost(child, data: data, record: record, brightness: brightness, platform: platform));
  await tester.pump();
}

/// The app [pumpDataHost] pumps, for `pumpAtTextScale`.
Widget dataHost(
  Widget child, {
  required DataBloc data,
  RecordBloc? record,
  Brightness brightness = Brightness.light,
  TargetPlatform platform = TargetPlatform.android,
}) {
  // The blocs sit below the Navigator, as on the Settings page, so a dialog sees them only if it provides them again.
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: bazaarTheme(brightness: brightness, platform: platform),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    locale: const Locale('en'),
    home: MultiBlocProvider(
      providers: [
        BlocProvider<DataBloc>.value(value: data),
        BlocProvider<RecordBloc>.value(value: record ?? recordBlocAt()),
      ],
      child: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// The context of the host's Scaffold, from which a test opens a dialog.
BuildContext hostContext(WidgetTester tester) => tester.element(find.byType(SingleChildScrollView).first);
