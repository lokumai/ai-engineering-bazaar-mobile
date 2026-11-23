import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/search_text.dart';

/// Every year the stop's trend was on [road], from its first month's to its last's.
List<int> yearsOf(CaravanStop stop, CaravanRoad road) {
  final first = road.months[stop.first].year;
  final last = road.months[stop.last].year;
  return [for (var year = first; year <= last; year++) year];
}

/// The stops a reader's choice keeps, in order (the web's `filterTrends`, `components/caravan/browse.ts`): those on the
/// road in [year] (any year when null), with every word of [query] in the title or the text.
///
/// Both sides are compared as the course search compares them, by [normalise] in [language] (review 5, finding 18): a
/// Turkish "ı" or "İ" typed either way, and a Persian word typed with a space where the text has a non-joiner, as
/// "چت بات" for "چت‌بات", are found.
List<CaravanStop> filterStops(CaravanRoad road, {int? year, String query = '', String language = 'en'}) {
  final words = [
    for (final word in query.split(RegExp(r'\s+')))
      if (normalise(word, language) case final term when term.isNotEmpty) term,
  ];
  return [
    for (final stop in road.stops)
      if ((year == null || yearsOf(stop, road).contains(year)) &&
          words.every(normalise('${stop.trend.title}\n${stop.trend.text}', language).contains))
        stop,
  ];
}
