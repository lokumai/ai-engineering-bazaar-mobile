import 'package:ai_engineering_bazaar/shared/design_system/widgets/readable_width.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Rect> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ReadableWidth(child: SizedBox.expand(key: Key('page'))));
  return tester.getRect(find.byKey(const Key('page')));
}

void main() {
  testWidgets('on a phone the page takes the whole screen', (tester) async {
    expect(await _pumpAt(tester, const Size(400, 800)), const Rect.fromLTWH(0, 0, 400, 800));
  });

  testWidgets("on a tablet the page keeps a phone's measure in the middle, its whole height", (tester) async {
    final rect = await _pumpAt(tester, const Size(1200, 900));
    expect(rect.width, ReadableWidth.text);
    expect(rect.height, 900);
    expect(rect.center.dx, 600);
  });

  // Review 10, finding 2: crossing the width dropped the state under it, and a Practice session started over.
  testWidgets('the page keeps its state as the screen turns past the width, both ways', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpWidget(const ReadableWidth(child: _Counter()));
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('1', skipOffstage: false), findsOneWidget);

    for (final size in [const Size(1200, 900), const Size(600, 900)]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(find.text('1'), findsOneWidget, reason: '$size');
    }
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _taps++),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('$_taps')),
    ),
  );
}
