part of 'content_bloc.dart';

sealed class ContentEvent {
  const ContentEvent();
}

/// The app started: open the content, then refresh it once.
final class ContentStarted extends ContentEvent {
  const ContentStarted();
}

/// Check the site for newer content: once per cold start after ready, and from Settings.
final class ContentRefreshRequested extends ContentEvent {
  const ContentRefreshRequested();
}
