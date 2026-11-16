import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';

/// Every year the stop's trend was on [road], from its first month's to its last's.
List<int> yearsOf(CaravanStop stop, CaravanRoad road) {
  final first = road.months[stop.first].year;
  final last = road.months[stop.last].year;
  return [for (var year = first; year <= last; year++) year];
}

/// The stops a reader's choice keeps, in order (the web's `filterTrends`, `components/caravan/browse.ts`): those on the
/// road in [year] (any year when null), with every word of [query] in the title or the text.
///
/// `toLowerCase`, which is the same in every locale, so a Turkish phone finds "interview" in "Interview" as the web's
/// note asks.
List<CaravanStop> filterStops(CaravanRoad road, {int? year, String query = ''}) {
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  return [
    for (final stop in road.stops)
      if ((year == null || yearsOf(stop, road).contains(year)) &&
          words.every('${stop.trend.title}\n${stop.trend.text}'.toLowerCase().contains))
        stop,
  ];
}
