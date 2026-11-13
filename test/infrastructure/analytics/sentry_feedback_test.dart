import 'package:ai_engineering_bazaar/infrastructure/analytics/sentry_feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('sends the message with its email masked, and no name or contact email', () async {
    final sent = <SentryFeedback>[];

    await sendSentryFeedback(
      'It froze; write to jane.doe@example.com',
      capture: (feedback) async {
        sent.add(feedback);
        return SentryId.newId();
      },
    );

    expect(sent.single.message, 'It froze; write to [REDACTED_EMAIL]');
    expect(sent.single.name, isNull);
    expect(sent.single.contactEmail, isNull);
  });

  test('throws when Sentry did not take the feedback', () async {
    expect(() => sendSentryFeedback('It froze', capture: (_) async => const SentryId.empty()), throwsStateError);
  });
}
