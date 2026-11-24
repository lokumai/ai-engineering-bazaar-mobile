import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_direction.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Review 5, finding 5: English in the Persian interface (a summary, a level's notes, a draft) was laid out right to
// left, its full stop at the start of the line.
void main() {
  Future<TextDirection> directionOf(WidgetTester tester, Widget content) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.rtl, child: content));
    return Directionality.of(tester.element(find.text('A summary.')));
  }

  testWidgets('English reads left to right in a right-to-left interface', (tester) async {
    expect(await directionOf(tester, const ContentDirection.english(child: Text('A summary.'))), TextDirection.ltr);
  });

  testWidgets('a document keeps the direction of its own language', (tester) async {
    expect(
      await directionOf(tester, const ContentDirection(dir: TextDir.rtl, child: Text('A summary.'))),
      TextDirection.rtl,
    );
    expect(
      await directionOf(tester, const ContentDirection(dir: TextDir.ltr, child: Text('A summary.'))),
      TextDirection.ltr,
    );
  });
}
