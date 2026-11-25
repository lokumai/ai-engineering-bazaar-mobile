@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/app.dart';
import 'package:ai_engineering_bazaar/app/shell/bazaar_shell.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/pages/home_page.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/spoken_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/bazaar_app_harness.dart';
import '../../support/content_fixture.dart';

final class _WholeSpeech implements ISpeech {
  @override
  Future<bool> canSpeak(String language) async => true;

  @override
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
    String title = '',
    String? noticeLanguage,
  }) async {
    for (var i = 0; i < texts.length; i++) {
      onPart(i);
    }
  }

  @override
  Stream<void> get interruptions => const Stream.empty();

  @override
  Stream<void> get resumes => const Stream.empty();

  @override
  Future<void> show(ShownReading? reading) async {}

  @override
  Future<void> stop() async {}
}

class _Deps extends FixtureAppDependencies {
  const _Deps();

  @override
  ISpeech createSpeech() => _WholeSpeech();
}

Future<int> _completedNotes(WidgetTester tester, {required bool secondShell}) async {
  await tester.pumpWidget(const App(dependencies: _Deps()));
  await pumpUntilFound(tester, find.byType(HomePage), maxPumps: 60);
  await tester.pump(const Duration(seconds: 3));
  final router = GoRouter.of(tester.element(find.byType(HomePage)));
  if (secondShell) {
    router.push('/quiz/alpha/first');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    router.push('/courses/alpha/first');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
  final listen = tester.element(find.byType(BazaarShell, skipOffstage: false).first).read<ListenCubit>();
  listen.start(
    const ListenSession(
      module: 'beta/third',
      track: Track.engineers,
      title: 'Third',
      language: 'en',
      parts: [
        SpokenPart(block: 0, text: 'one'),
        SpokenPart(block: 1, text: 'two'),
      ],
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  var notes = 0;
  for (var i = 0; i < 4; i++) {
    if (find.byKey(const ValueKey('listen-completed'), skipOffstage: false).evaluate().isEmpty) break;
    notes++;
    ScaffoldMessenger.of(tester.element(find.byKey(const ValueKey('listen-completed')).first)).removeCurrentSnackBar();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
  return notes;
}

void main() {
  testWidgets('a module heard whole says so once', (tester) async {
    expect(await _completedNotes(tester, secondShell: false), 1);
  });

  // Review 12, A1: a module opened from a full-screen page comes in a second shell, which had its own listeners, so
  // the note and its Undo showed twice and the completion was sent twice.
  testWidgets('a module heard whole in a second shell, opened from a full-screen page, says so once', (tester) async {
    expect(await _completedNotes(tester, secondShell: true), 1);
    expect(find.byType(BazaarShell, skipOffstage: false), findsNWidgets(2), reason: 'the case the review found');
  });
}
