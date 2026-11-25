import 'package:ai_engineering_bazaar/shared/utils/laid_out.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The release build's walk-through (review 11): a figure's check on a page under another read its place through a
/// transition never laid out, and "RenderBox was not laid out" was thrown, in release too.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a box laid out under a box that never was has no place, and has one once its parent is laid out', () {
    final child = RenderConstrainedBox(additionalConstraints: BoxConstraints.tight(const Size(10, 10)))
      ..layout(const BoxConstraints());
    final parent = RenderPadding(padding: const EdgeInsets.all(4), child: child);
    PipelineOwner().rootNode = parent;
    expect(child.hasSize, isTrue);
    expect(parent.hasSize, isFalse);
    expect(laidOutTopLeft(child), isNull);
    expect(laidOutRect(child), isNull);

    parent.layout(BoxConstraints.loose(const Size(100, 100)));
    expect(laidOutTopLeft(child), isNotNull);
    expect(laidOutRect(child, ancestor: parent), const Rect.fromLTWH(4, 4, 10, 10));
    expect(laidOutTopLeft(child, ancestor: parent), const Offset(4, 4));
  });

  test('a box not attached, or never laid out, has no place', () {
    expect(laidOutTopLeft(RenderConstrainedBox(additionalConstraints: const BoxConstraints())), isNull);
  });
}
