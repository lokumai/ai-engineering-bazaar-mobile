import 'package:equatable/equatable.dart';

/// Where the reader is with the Apprentice's tour (plan 11.3), kept on this device apart from the record.
final class TourRecord extends Equatable {
  const TourRecord({this.asking = false, this.guiding = false, this.seen = const {}});

  /// The Apprentice is to ask on Home whether to show the reader around: set once, at the end of the first run's
  /// Welcome, and never for a reader who had used the app before.
  final bool asking;

  /// The reader said yes: each page is shown the first time it is opened, until it is [seen].
  final bool guiding;

  /// The pages already shown, by [TourPage] name.
  final Set<String> seen;

  TourRecord copyWith({bool? asking, bool? guiding, Set<String>? seen}) =>
      TourRecord(asking: asking ?? this.asking, guiding: guiding ?? this.guiding, seen: seen ?? this.seen);

  @override
  List<Object?> get props => [asking, guiding, seen];
}

/// Keeps the [TourRecord]: the tour feature's port, which `lib/app/di/` fills with the app's file flags.
abstract interface class ITourStore {
  Future<TourRecord> load();

  Future<void> save(TourRecord record);
}

/// A store that keeps the record in memory only.
final class MemoryTourStore implements ITourStore {
  MemoryTourStore([this.kept = const TourRecord()]);

  TourRecord kept;

  @override
  Future<TourRecord> load() async => kept;

  @override
  Future<void> save(TourRecord record) async => kept = record;
}
