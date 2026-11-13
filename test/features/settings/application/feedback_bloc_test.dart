import 'package:ai_engineering_bazaar/features/settings/application/feedback_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';

void main() {
  late MockFeedbackSender sender;

  setUp(() => sender = MockFeedbackSender());

  blocTest<FeedbackBloc, FeedbackState>(
    'sends the trimmed text and says it was sent',
    setUp: () => when(() => sender.send(any())).thenAnswer((_) async {}),
    build: () => FeedbackBloc(sender: sender),
    act: (bloc) => bloc.add(const FeedbackSubmitted('  The quiz froze  ')),
    expect: () => const [FeedbackSending(), FeedbackSent()],
    verify: (_) => verify(() => sender.send('The quiz froze')).called(1),
  );

  blocTest<FeedbackBloc, FeedbackState>(
    'says it was not sent when the sender throws',
    setUp: () => when(() => sender.send(any())).thenThrow(StateError('off')),
    build: () => FeedbackBloc(sender: sender),
    act: (bloc) => bloc.add(const FeedbackSubmitted('The quiz froze')),
    expect: () => const [FeedbackSending(), FeedbackFailed()],
  );

  blocTest<FeedbackBloc, FeedbackState>(
    'sends nothing for a blank text',
    build: () => FeedbackBloc(sender: sender),
    act: (bloc) => bloc.add(const FeedbackSubmitted('   ')),
    expect: () => const <FeedbackState>[],
    verify: (_) => verifyNever(() => sender.send(any())),
  );

  blocTest<FeedbackBloc, FeedbackState>(
    'sends one report when the button is tapped twice while the first is on its way',
    setUp: () =>
        when(() => sender.send(any())).thenAnswer((_) => Future<void>.delayed(const Duration(milliseconds: 10))),
    build: () => FeedbackBloc(sender: sender),
    act: (bloc) => bloc
      ..add(const FeedbackSubmitted('first'))
      ..add(const FeedbackSubmitted('second')),
    wait: const Duration(milliseconds: 50),
    expect: () => const [FeedbackSending(), FeedbackSent()],
    verify: (_) => verify(() => sender.send(any())).called(1),
  );
}
