import 'package:ai_engineering_bazaar/app/shell/floating_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _room = Size(400, 600);
final _ball = find.byKey(const ValueKey('ball'));

Future<List<Offset>> _pump(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  bool reduced = false,
  VoidCallback? onTap,
}) async {
  final rests = <Offset>[];
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox.fromSize(
            size: _room,
            child: FloatingDock(
              size: 58,
              onRest: rests.add,
              child: GestureDetector(
                onTap: onTap,
                child: const ColoredBox(key: ValueKey('ball'), color: Color(0xff000000)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return rests;
}

Rect _roomRect(WidgetTester tester) => tester.getRect(find.byType(FloatingDock));

void main() {
  testWidgets('it starts in the corner at the page foot, on the end side', (tester) async {
    await _pump(tester);
    final room = _roomRect(tester);
    expect(tester.getRect(_ball).bottomRight, room.bottomRight - const Offset(16, 16));

    await _pump(tester, direction: TextDirection.rtl);
    expect(tester.getRect(_ball).bottomLeft, room.bottomLeft + const Offset(16, -16));
  });

  testWidgets('a finger drags it, and it stays where it is let go', (tester) async {
    final rests = await _pump(tester);
    final before = tester.getRect(_ball);
    final gesture = await tester.startGesture(before.center);
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(-10, -10));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pump();
    expect(tester.getRect(_ball).topLeft, before.topLeft - const Offset(200, 200));
    expect(rests, hasLength(1));
  });

  testWidgets('a flick throws it off the edges, inside the page, until it rests', (tester) async {
    final rests = await _pump(tester);
    final room = _roomRect(tester).deflate(16);
    await tester.flingFrom(tester.getRect(_ball).center, const Offset(-150, -40), 3000);
    var bounced = false;
    var last = tester.getRect(_ball).left;
    var goingLeft = true;
    for (var i = 0; i < 300 && rests.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final ball = tester.getRect(_ball);
      expect(room.contains(ball.topLeft) && room.contains(ball.bottomRight - const Offset(0.01, 0.01)), isTrue);
      if (goingLeft && ball.left > last + 0.5) {
        bounced = true;
        goingLeft = false;
      }
      last = ball.left;
    }
    expect(bounced, isTrue, reason: 'the left edge turned it back');
    expect(rests, hasLength(1), reason: 'it comes to rest');
    final resting = tester.getRect(_ball);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getRect(_ball), resting);
  });

  testWidgets('with reduced motion a flick only drops it where the finger leaves it', (tester) async {
    final rests = await _pump(tester, reduced: true);
    final start = tester.getRect(_ball);
    await tester.flingFrom(start.center, const Offset(-100, 0), 3000);
    await tester.pump();
    expect(rests, hasLength(1));
    final dropped = tester.getRect(_ball);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getRect(_ball), dropped);
  });

  testWidgets('a tap still reaches its child, and the room around it passes taps to the page under it', (tester) async {
    var ball = 0;
    var page = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => page++,
                child: const ColoredBox(color: Color(0xffffffff)),
              ),
            ),
            Positioned.fill(
              child: FloatingDock(
                size: 58,
                child: GestureDetector(
                  onTap: () => ball++,
                  child: const ColoredBox(key: ValueKey('ball'), color: Color(0xff000000)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tap(_ball);
    await tester.tapAt(const Offset(40, 40));
    expect((ball, page), (1, 1));
  });
}
