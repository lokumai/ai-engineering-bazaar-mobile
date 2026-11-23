import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/presentation/listen_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Review 7, finding 16: in Persian the line filled from the right while previous, play and next ran left to right.
  for (final direction in TextDirection.values) {
    testWidgets('a quarter heard fills the left quarter, ${direction.name}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: bazaarTheme(brightness: Brightness.light, platform: TargetPlatform.android),
          home: Directionality(
            textDirection: direction,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: ListenProgress(
                  state: ListenOn(
                    module: 'alpha/first',
                    track: Track.engineers,
                    title: 'First',
                    index: 0,
                    count: 4,
                    playing: true,
                    rate: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final fill = tester.getRect(
        find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(ColoredBox)),
      );
      expect(fill.left, 0);
      expect(fill.width, 100);
    });
  }
}
