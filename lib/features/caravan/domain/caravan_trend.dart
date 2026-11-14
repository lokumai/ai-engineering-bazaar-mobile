import 'package:equatable/equatable.dart';

/// The kinds of reading a trend points to, in the order the web lists a module's References.
enum CaravanSourceKind { articles, videos, tools, repositories }

/// One trend on the Caravan's road (web M62, D116): what was new in AI engineering, from the month it started to the
/// month people stopped calling it new.
///
/// Months are the first day of the month, in UTC. [peak] is how strong the trend was at its height, 1 to 5; the road's
/// land rises where many strong trends overlap.
final class CaravanTrend extends Equatable {
  const CaravanTrend({
    required this.id,
    required this.title,
    required this.text,
    required this.start,
    required this.end,
    required this.peak,
    this.modules = const [],
    this.sources = const [],
  });

  final String id;
  final String title;
  final String text;
  final DateTime start;

  /// The month it ended, or null while people still call it new.
  final DateTime? end;
  final int peak;

  /// The names of the course's modules on the subject (the last segment of a module key, as the web's
  /// `curriculum.yaml` names them); a name the course does not have is dropped where the trend is drawn.
  final List<String> modules;

  /// The kinds of reading the trend points to.
  final List<CaravanSourceKind> sources;

  @override
  List<Object?> get props => [id, title, text, start, end, peak, modules, sources];
}
