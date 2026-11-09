part of 'content_bloc.dart';

sealed class ContentState extends Equatable {
  const ContentState();

  @override
  List<Object?> get props => [];
}

/// The content is being opened.
final class ContentLoading extends ContentState {
  const ContentLoading();
}

/// The content is open; [refresh] says where the latest refresh stands.
final class ContentReady extends ContentState {
  const ContentReady({required this.index, required this.origin, required this.notice, required this.refresh});

  final BundleIndex index;
  final ContentOrigin origin;
  final ContentNotice? notice;
  final RefreshStatus refresh;

  /// This content with [refresh] as its refresh status.
  ContentReady withRefresh(RefreshStatus refresh) =>
      ContentReady(index: index, origin: origin, notice: notice, refresh: refresh);

  @override
  List<Object?> get props => [index, origin, notice, refresh];
}

/// The bundled content cannot be opened; the app shows [code] full screen.
final class ContentBroken extends ContentState {
  const ContentBroken({required this.code});

  final ContentErrorCode code;

  @override
  List<Object?> get props => [code];
}

/// Where a refresh of the content stands (spec 3.4.2).
sealed class RefreshStatus extends Equatable {
  const RefreshStatus();

  @override
  List<Object?> get props => [];
}

/// No refresh has run yet.
final class RefreshIdle extends RefreshStatus {
  const RefreshIdle();
}

/// A refresh is running.
final class RefreshChecking extends RefreshStatus {
  const RefreshChecking();
}

/// The site publishes nothing newer.
final class RefreshUpToDate extends RefreshStatus {
  const RefreshUpToDate();
}

/// Newer content was downloaded and is current.
final class RefreshUpdated extends RefreshStatus {
  const RefreshUpdated();
}

/// The refresh stopped at [code]; the content is unchanged.
final class RefreshFailed extends RefreshStatus {
  const RefreshFailed(this.code);

  final ContentErrorCode code;

  @override
  List<Object?> get props => [code];
}

/// The site publishes no API major this app reads.
final class RefreshNeedsAppUpdate extends RefreshStatus {
  const RefreshNeedsAppUpdate();
}
