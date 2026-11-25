@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/shell/listen_completion.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/spoken_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _session = ListenSession(
  module: 'alpha/first',
  track: Track.engineers,
  title: 'First',
  language: 'en',
  parts: [SpokenPart(block: 0, text: 'One.')],
);

Future<ListenCubit> _pump(WidgetTester tester) async {
  // No voice at all: a speak ends at once, with no part started.
  final listen = ListenCubit(speech: const NoSpeech());
  addTearDown(listen.close);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<ListenCubit>.value(
        value: listen,
        child: const ListenNotStarted(child: Scaffold(body: SizedBox.expand())),
      ),
    ),
  );
  return listen;
}

void main() {
  // Review 2 finding 6, review 5 finding 11: the player closed without a word when the phone's voice did not start.
  testWidgets('a reading the phone did not start says so', (tester) async {
    final listen = await _pump(tester);
    listen.start(_session);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listen-not-started')), findsOneWidget);
    expect(find.textContaining('Listening stopped. Your place is kept'), findsOneWidget);
  });

  testWidgets('a reading stopped says nothing of it', (tester) async {
    final listen = await _pump(tester);
    listen
      ..start(_session)
      ..stop();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listen-not-started')), findsNothing);
  });
}
