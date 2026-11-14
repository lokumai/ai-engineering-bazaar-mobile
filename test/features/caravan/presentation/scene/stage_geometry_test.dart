import 'package:ai_engineering_bazaar/features/caravan/domain/sample_trends.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/caravan_journey.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_art.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_stage.dart';

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final road = SampleCaravan.road('en');

  group('the journey', () {
    test('walks toward its target, slowing as it nears, and arrives', () {
      final journey = CaravanJourney()..walkTo(2);
      journey.step(1 / 60);
      expect(journey.t, inExclusiveRange(0, 2));
      expect(journey.velocity, greaterThan(0));
      for (var i = 0; i < 300; i++) {
        journey.step(1 / 60);
      }
      expect(journey.t, 2);
      expect(journey.moving, isFalse);
      expect(journey.velocity, 0);
    });

    test('is there at once when instant or under reduced motion', () {
      final journey = CaravanJourney()..walkTo(3, instant: true);
      expect(journey.t, 3);
      journey
        ..walkTo(5)
        ..step(1 / 60, reduced: true);
      expect(journey.t, 5);
    });

    test('a drag sets the place and the pace, and rest stands it', () {
      final journey = CaravanJourney(at: 1)..dragTo(1.5, dt: 0.5);
      expect(journey.t, 1.5);
      expect(journey.target, 1.5);
      expect(journey.velocity, 1);
      journey.rest();
      expect(journey.velocity, 0);
    });

    test('a quiet place tells nobody until announced', () {
      var heard = 0;
      final journey = CaravanJourney()..addListener(() => heard++);
      journey.place(4);
      expect(journey.t, 4);
      expect(heard, 0);
      journey.announce();
      expect(heard, 1);
    });
  });

  group('the stage geometry', () {
    test('the zoom fits the height and the phone width', () {
      expect(StageGeometry.zoomFor(const Size(393, 300)), closeTo((300 - 24 - 40 - 12) / 219, 1e-9));
      expect(StageGeometry.zoomFor(const Size(393, 1000)), 1.15, reason: 'no larger than the most');
      expect(StageGeometry.zoomFor(const Size(393, 100)), 0.5, reason: 'no smaller than half');
    });

    test('a chosen stop stands past the middle, and the leader is the month it is at', () {
      final geo = StageGeometry(const Size(393, 300), road);
      final stop = road.stops[5];
      final camera = geo.cameraFor(stop.at);
      final x = stop.at * geo.month - geo.cameraX(camera);
      expect(x / 393, closeTo(StageGeometry.focus, 1e-9));
      expect(geo.leaderMonth(camera), lessThan(stop.at), reason: 'the caravan arrives just before the stall');
    });

    test('the props stand above the caravan road', () {
      final geo = StageGeometry(const Size(393, 300), road);
      for (var x = 0.0; x < road.length * geo.month; x += 50) {
        expect(geo.ground(x), lessThan(geo.walk(x)));
      }
    });
  });

  group('the names over the stops', () {
    // Wide, so several stops stand in view at once.
    const size = Size(1200, 300);
    final geo = StageGeometry(size, road);
    final labels = [
      for (final stop in road.stops) StopLabel(stop.trend.title, maxWidth: 300, textDirection: TextDirection.ltr),
    ];
    tearDownAll(() {
      for (final label in labels) {
        label.dispose();
      }
    });

    ShadowStagePainter painter(int selected, double at) => ShadowStagePainter(
      art: StageArt(geo, mirrored: false),
      journey: CaravanJourney(at: at),
      clock: ValueNotifier(0),
      selected: selected,
      labels: labels,
      mirrored: false,
      reduced: true,
    );

    test('only the chosen stop is named, never the ones the caravan passed', () {
      final at = geo.cameraFor(road.stops[6].at);
      expect((Canvas canvas) => painter(6, at).paint(canvas, size), paintsExactlyCountTimes(#drawParagraph, 1));
    });

    test('a chosen stop out of view is not named on the cloth\'s edge', () {
      final at = geo.cameraFor(road.stops[0].at);
      expect((Canvas canvas) => painter(road.stops.length - 1, at).paint(canvas, size), isNot(paints..paragraph()));
    });

    test('the name fades as its prop nears the edge and stays inside the cloth', () {
      const box = Size(120, 22);
      ({Rect rect, double opacity})? at(double x, {bool mirrored = false}) => stopLabelPlace(
        shown: [(index: 2, x: x, top: 150)],
        selected: 2,
        box: box,
        stage: const Size(393, 300),
        mirrored: mirrored,
      );
      expect(at(200)!.opacity, 1);
      expect(at(30)!.opacity, inExclusiveRange(0, 1));
      expect(at(30)!.rect.left, greaterThanOrEqualTo(StageFrame.side));
      expect(at(4), isNull);
      expect(at(393 - 30, mirrored: true)!.opacity, at(30)!.opacity);
      expect(
        stopLabelPlace(
          shown: [(index: 1, x: 200, top: 150)],
          selected: 2,
          box: box,
          stage: const Size(393, 300),
          mirrored: false,
        ),
        isNull,
      );
    });
  });

  group('the art', () {
    test('a stop stands as a serai, a tent, a stall or a stone by its strength', () {
      expect(propKindOf(5), PropKind.serai);
      expect(propKindOf(4), PropKind.tent);
      expect(propKindOf(3), PropKind.stall);
      expect(propKindOf(2), PropKind.stone);
      expect(propOf(0, 5).top, -150);
      expect(propOf(1, 2).top, -70);
    });

    test('a pale colour of goods is darkened as ink on the page', () {
      expect(inkOf(1), isNot(packOf(1)), reason: 'the cream');
      expect(inkOf(0), packOf(0));
    });

    test('the camels are kept by their loads, so a frame builds none', () {
      expect(
        identical(Puppets.camel(const [Color(0xff123456)], 0), Puppets.camel(const [Color(0xff123456)], 0)),
        isTrue,
      );
    });

    test('every landmark and the post draw', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      for (var place = 0; place < 5; place++) {
        landmarkOf(place).paint(canvas);
      }
      postPiece.paint(canvas);
      Puppets.leader.paint(canvas, seconds: 1.2, walking: true);
      Puppets.driver.paint(canvas, seconds: 1.2, walking: true);
      recorder.endRecording().dispose();
    });
  });
}
