import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a place is found while it is on the screen, the one drawn last, and forgotten once it leaves', (
    tester,
  ) async {
    const a = Key('a');
    const b = Key('b');
    expect(TourTarget.contextOf(TourSpots.band), isNull);

    await tester.pumpWidget(
      const TourTarget(
        spot: TourSpots.band,
        child: SizedBox(key: a),
      ),
    );
    expect(TourTarget.contextOf(TourSpots.band)?.widget, isA<TourTarget>());
    expect(
      find.descendant(of: find.byWidget(TourTarget.contextOf(TourSpots.band)!.widget), matching: find.byKey(a)),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const Column(
        children: [
          TourTarget(
            spot: TourSpots.band,
            child: SizedBox(key: a),
          ),
          TourTarget(
            spot: TourSpots.band,
            child: SizedBox(key: b),
          ),
        ],
      ),
    );
    final last = TourTarget.contextOf(TourSpots.band)!;
    expect(find.descendant(of: find.byWidget(last.widget), matching: find.byKey(b)), findsOneWidget);

    await tester.pumpWidget(
      const TourTarget(
        spot: TourSpots.tabs,
        child: SizedBox(key: a),
      ),
    );
    expect(TourTarget.contextOf(TourSpots.band), isNull);
    expect(TourTarget.contextOf(TourSpots.tabs), isNotNull, reason: 'it took the new name');

    await tester.pumpWidget(const SizedBox());
    expect(TourTarget.contextOf(TourSpots.tabs), isNull);
  });
}
