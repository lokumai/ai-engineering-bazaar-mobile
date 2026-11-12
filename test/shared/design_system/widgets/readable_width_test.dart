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
    expect(rect.width, ReadableWidth.maxWidth);
    expect(rect.height, 900);
    expect(rect.center.dx, 600);
  });
}
