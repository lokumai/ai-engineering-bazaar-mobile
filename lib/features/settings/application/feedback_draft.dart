/// What the reader wrote under Report a problem and has not sent, kept in memory while the app runs: leaving the page,
/// by Back or by another tab, threw the text away (walk-through 2026-11-24). Never written to the device and never
/// logged; a sent report clears it.
class FeedbackDraft {
  String text = '';

  @override
  String toString() => 'FeedbackDraft([REDACTED])';
}
