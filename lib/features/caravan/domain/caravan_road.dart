import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_trend.dart';
import 'package:equatable/equatable.dart';

/// The months between [from] and [to], counted by calendar month: 0 for the same month.
int monthsBetween(DateTime from, DateTime to) => (to.year - from.year) * 12 + to.month - from.month;

/// The first day of the month [count] months after [month].
DateTime addMonths(DateTime month, int count) => DateTime.utc(month.year, month.month + count);

/// One trend where it stands on the road: its first and last month as indexes into [CaravanRoad.months], and [at],
/// the spot its stop stands on, in months from the road's start.
final class CaravanStop extends Equatable {
  const CaravanStop({
    required this.trend,
    required this.index,
    required this.first,
    required this.last,
    required this.at,
  });

  final CaravanTrend trend;

  /// The trend's place among the stops, in the order they start.
  final int index;
  final int first;
  final int last;
  final double at;

  @override
  List<Object?> get props => [trend, index, first, last, at];
}

/// The road the caravan walks, month by month (web M91, `scene/model.ts` and `lib/content/caravan.ts`): its months,
/// how busy each month was, and where each trend's stop stands. It is pure arithmetic over the trends, so the stage, the
/// strip and the cubit read the same road.
final class CaravanRoad extends Equatable {
  const CaravanRoad._({required this.months, required this.norm, required this.stops});

  /// The road from [first] through [through], stretched to the last month a trend reaches, with the [trends] in the
  /// order they start (a trend that starts with another keeps its order in [trends]).
  factory CaravanRoad.of(List<CaravanTrend> trends, {required DateTime first, required DateTime through}) {
    var last = through;
    for (final trend in trends) {
      final end = trend.end ?? through;
      if (end.isAfter(last)) last = end;
    }
    final count = monthsBetween(first, last) + 1;
    final months = [for (var i = 0; i < count; i++) addMonths(first, i)];

    final ordered = [...trends]..sort((a, b) => a.start.compareTo(b.start));
    final totals = List<double>.filled(count, 0);
    final spans = <(CaravanTrend, int, int)>[];
    for (final trend in ordered) {
      final from = monthsBetween(first, trend.start).clamp(0, count - 1);
      final to = monthsBetween(first, trend.end ?? through).clamp(from, count - 1);
      spans.add((trend, from, to));
      final levels = strengthShape(to - from + 1, trend.peak);
      for (var k = 0; k < levels.length; k++) {
        totals[from + k] += levels[k];
      }
    }
    final most = totals.fold<double>(0, math.max);
    final norm = [for (final total in totals) most > 0 ? total / most : 0.0];

    final stops = <CaravanStop>[];
    for (var i = 0; i < spans.length; i++) {
      final (trend, from, to) = spans[i];
      final together = [
        for (final span in spans)
          if (span.$2 == from) span.$1,
      ];
      final slot = together.indexOf(trend);
      // A quarter into its first month, or spread across the month when several start together (web `place`).
      final at = from + 0.25 + (together.length > 1 ? slot * 0.5 : 0.25);
      stops.add(CaravanStop(trend: trend, index: i, first: from, last: to, at: at));
    }
    return CaravanRoad._(
      months: List.unmodifiable(months),
      norm: List.unmodifiable(norm),
      stops: List.unmodifiable(stops),
    );
  }

  /// Every month on the road, in order.
  final List<DateTime> months;

  /// Per month, the summed strength of the trends on the road, scaled to the busiest month (0 to 1).
  final List<double> norm;

  /// The stops, one per trend, in the order the trends start.
  final List<CaravanStop> stops;

  /// The road's length in months.
  int get length => months.length;

  /// The land's height at the fractional month [t]: a Catmull-Rom curve through the months' centres (web `heatAt`).
  double heatAt(double t) {
    if (norm.isEmpty) return 0;
    final i = (t - 0.5).floor();
    final f = t - 0.5 - i;
    double g(int k) => norm[k.clamp(0, norm.length - 1)];
    final p0 = g(i - 1);
    final p1 = g(i);
    final p2 = g(i + 1);
    final p3 = g(i + 2);
    final v =
        0.5 *
        (2 * p1 + (-p0 + p2) * f + (2 * p0 - 5 * p1 + 4 * p2 - p3) * f * f + (-p0 + 3 * p1 - 3 * p2 + p3) * f * f * f);
    return v.clamp(0, 1.05);
  }

  /// The stops whose trend is on the road at the fractional month [t], the latest [max] of them (web `onRoad`): the
  /// goods the camels carry there.
  List<CaravanStop> onRoad(double t, {int max = 6}) {
    final on = [
      for (final stop in stops)
        if (t >= stop.first && t <= stop.last + 1) stop,
    ];
    return on.length > max ? on.sublist(on.length - max) : on;
  }

  /// The stop nearest the fractional month [t]; -1 when the road has none.
  int nearestStop(double t) {
    var best = -1;
    var distance = double.infinity;
    for (final stop in stops) {
      final d = (stop.at - t).abs();
      if (d < distance) {
        distance = d;
        best = stop.index;
      }
    }
    return best;
  }

  /// Each year the road passes, with the index of its first month on the road.
  List<({int year, int at})> get yearStarts => [
    for (var i = 0; i < months.length; i++)
      if (i == 0 || months[i].month == 1) (year: months[i].year, at: i),
  ];

  @override
  List<Object?> get props => [months, norm, stops];
}

/// A trend's strength over the [span] months it was on the road: a rise and a fall to [peak], each month at least 1
/// (the web sample's `shape`). It is a placeholder for the measured strength the web's pipeline will publish.
List<int> strengthShape(int span, int peak) => [
  for (var k = 0; k < span; k++) math.max(1, (peak * math.pow(math.sin(math.pi * (k + 0.5) / span), 0.7)).round()),
];
