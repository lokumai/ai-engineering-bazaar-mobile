import 'package:ai_engineering_bazaar/core/security/sensitive_data_scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The shape of [Sentry.captureFeedback] that [sendSentryFeedback] calls.
typedef CaptureFeedback = Future<SentryId> Function(SentryFeedback feedback);

/// Sends [message] as Sentry user feedback, with its emails and secrets masked as every other exit masks them
/// (`maskEmails`, `maskSecrets`), before it leaves the device; the `beforeSendFeedback` hook then scrubs the rest of
/// the event. No name and no contact email are sent. Throws a [StateError] when the SDK did not take it (Sentry off, or
/// the event dropped), so the page says it was not sent; offline, the SDK keeps it and sends it later.
Future<void> sendSentryFeedback(String message, {CaptureFeedback capture = Sentry.captureFeedback}) async {
  final id = await capture(SentryFeedback(message: maskEmails(maskSecrets(message))));
  if (id == const SentryId.empty()) throw StateError('Sentry did not take the feedback');
}
