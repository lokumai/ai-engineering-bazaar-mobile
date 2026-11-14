import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_browse.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final road = CaravanRoad.of(
    [
      CaravanTrend(
        id: 'early',
        title: 'Early Interview',
        text: 'The first trend.',
        start: DateTime.utc(2023, 3),
        end: DateTime.utc(2023, 8),
        peak: 3,
      ),
      CaravanTrend(
        id: 'long',
        title: 'Long road',
        text: 'Spans the turn of two years.',
        start: DateTime.utc(2023, 11),
        end: DateTime.utc(2025, 2),
        peak: 4,
      ),
      CaravanTrend(
        id: 'open',
        title: 'Still new',
        text: 'Open at the end of the road.',
        start: DateTime.utc(2025, 6),
        end: null,
        peak: 2,
      ),
    ],
    first: DateTime.utc(2023),
    through: DateTime.utc(2026, 3),
  );

  List<String> ids(List<CaravanStop> stops) => [for (final stop in stops) stop.trend.id];

  test('a trend is under every year its span touches, an open one up to the road end', () {
    expect(yearsOf(road.stops[0], road), [2023]);
    expect(yearsOf(road.stops[1], road), [2023, 2024, 2025]);
    expect(yearsOf(road.stops[2], road), [2025, 2026]);
  });

  test('no choice keeps every stop in order', () {
    expect(ids(filterStops(road)), ['early', 'long', 'open']);
  });

  test('a year keeps the trends on the road that year', () {
    expect(ids(filterStops(road, year: 2024)), ['long']);
    expect(ids(filterStops(road, year: 2026)), ['open']);
    expect(filterStops(road, year: 2030), isEmpty);
  });

  test('every word of the search must be in the title or the text, in any case', () {
    expect(ids(filterStops(road, query: 'interview')), ['early']);
    expect(ids(filterStops(road, query: '  TURN   years ')), ['long']);
    expect(ids(filterStops(road, query: 'road end')), ['open']);
    expect(filterStops(road, query: 'road nowhere'), isEmpty);
  });

  test('a year and a search together', () {
    expect(ids(filterStops(road, year: 2025, query: 'open')), ['open']);
    expect(filterStops(road, year: 2023, query: 'open'), isEmpty);
  });
}
