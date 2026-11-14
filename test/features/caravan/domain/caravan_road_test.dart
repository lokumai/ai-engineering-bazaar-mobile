import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_trend.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/sample_trends.dart';
import 'package:flutter_test/flutter_test.dart';

CaravanTrend _trend(String id, DateTime start, DateTime? end, {int peak = 3}) =>
    CaravanTrend(id: id, title: id, text: id, start: start, end: end, peak: peak);

void main() {
  final jan = DateTime.utc(2024);
  final jun = DateTime.utc(2024, 6);
  final dec = DateTime.utc(2024, 12);

  test('monthsBetween and addMonths count calendar months across years', () {
    expect(monthsBetween(DateTime.utc(2022, 11), DateTime.utc(2023, 2)), 3);
    expect(addMonths(DateTime.utc(2022, 11), 3), DateTime.utc(2023, 2));
    expect(addMonths(DateTime.utc(2022, 11), 0), DateTime.utc(2022, 11));
  });

  test('the road runs from its first month through its last, stretched to a trend that ends later', () {
    final road = CaravanRoad.of([_trend('a', jan, DateTime.utc(2025, 2))], first: jan, through: dec);
    expect(road.months.first, jan);
    expect(road.months.last, DateTime.utc(2025, 2));
    expect(road.length, 14);
  });

  test('an open trend reaches the last month, and its stop stands a half month into its first month', () {
    final road = CaravanRoad.of([_trend('open', jun, null)], first: jan, through: dec);
    final stop = road.stops.single;
    expect(stop.first, 5);
    expect(stop.last, 11);
    expect(stop.at, 5.5);
  });

  test('trends that start in the same month spread across it, in the order given', () {
    final road = CaravanRoad.of([_trend('a', jun, dec), _trend('b', jun, dec)], first: jan, through: dec);
    expect(road.stops.map((stop) => stop.at), [5.25, 5.75]);
    expect(road.stops.map((stop) => stop.trend.id), ['a', 'b']);
  });

  test('the stops are in the order the trends start, each with its place', () {
    final road = CaravanRoad.of([_trend('late', dec, null), _trend('early', jan, jun)], first: jan, through: dec);
    expect(road.stops.map((stop) => stop.trend.id), ['early', 'late']);
    expect(road.stops.map((stop) => stop.index), [0, 1]);
  });

  test('the busiest month is 1 and a month no trend reaches is 0', () {
    final road = CaravanRoad.of([_trend('a', jan, DateTime.utc(2024, 3), peak: 5)], first: jan, through: dec);
    expect(road.norm.reduce((a, b) => a > b ? a : b), 1);
    expect(road.norm.last, 0);
  });

  test('a road with no trend is flat', () {
    final road = CaravanRoad.of(const [], first: jan, through: dec);
    expect(road.norm, everyElement(0));
    expect(road.heatAt(3), 0);
    expect(road.nearestStop(3), -1);
  });

  test('the land passes through each month at its centre and stays within its bounds', () {
    final road = SampleCaravan.road('en');
    for (var i = 0; i < road.length; i++) {
      expect(road.heatAt(i + 0.5), closeTo(road.norm[i], 1e-9));
    }
    for (var t = -2.0; t < road.length + 2; t += 0.37) {
      expect(road.heatAt(t), inInclusiveRange(0, 1.05));
    }
  });

  test('the camels carry the trends on the road where they are, the latest six', () {
    final road = SampleCaravan.road('en');
    final at = road.stops[4].at;
    final load = road.onRoad(at);
    expect(load, contains(road.stops[4]));
    expect(load.length, lessThanOrEqualTo(6));
    expect(road.onRoad(at, max: 2), load.sublist(load.length - 2));
  });

  test('the nearest stop is found from either side', () {
    final road = SampleCaravan.road('en');
    final stop = road.stops[7];
    expect(road.nearestStop(stop.at - 0.1), 7);
    expect(road.nearestStop(stop.at + 0.1), 7);
    expect(road.nearestStop(-50), 0);
    expect(road.nearestStop(500), road.stops.length - 1);
  });

  test('each year starts once, the first at the road start', () {
    final road = SampleCaravan.road('en');
    expect(road.yearStarts.map((y) => y.year), [2022, 2023, 2024, 2025, 2026]);
    expect(road.yearStarts.first.at, 0);
    expect(road.yearStarts[1].at, 2);
  });

  test('a strength shape rises and falls to its peak and is never below 1', () {
    final shape = strengthShape(7, 5);
    expect(shape.reduce((a, b) => a > b ? a : b), 5);
    expect(shape, everyElement(greaterThanOrEqualTo(1)));
    expect(shape.first, lessThan(shape[3]));
    expect(strengthShape(1, 4), [4]);
  });

  group('the sample', () {
    test('has the same trends in every language, each with its own words', () {
      final en = SampleCaravan.trends('en');
      for (final language in ['tr', 'fa']) {
        final other = SampleCaravan.trends(language);
        expect(other.map((trend) => trend.id), en.map((trend) => trend.id));
        for (var i = 0; i < en.length; i++) {
          // Vibe coding keeps its English name in Turkish, as Turkish writers use it.
          if (!(language == 'tr' && en[i].id == 'vibe_coding')) {
            expect(other[i].title, isNot(en[i].title), reason: other[i].id);
          }
          expect(other[i].text, isNot(en[i].text), reason: other[i].id);
        }
      }
    });

    test('falls back to English for a language it does not have', () {
      expect(SampleCaravan.trends('de'), SampleCaravan.trends('en'));
    });

    test('runs from November 2022 through November 2026, 22 stops in order', () {
      final road = SampleCaravan.road('en');
      expect(road.length, 49);
      expect(road.stops, hasLength(22));
      for (var i = 1; i < road.stops.length; i++) {
        expect(road.stops[i].at, greaterThan(road.stops[i - 1].at));
      }
    });
  });
}
