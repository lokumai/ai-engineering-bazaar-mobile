import 'package:flutter/rendering.dart';

/// Where [box]'s top left corner is, in global coordinates or in [ancestor]'s, or null when [box] or a box between it
/// and there has never been laid out: a page under another one, or a page in the frame its route comes in, is built
/// before it is laid out, and a size read there throws "RenderBox was not laid out" even in a release build (review 11,
/// the release build's walk-through).
Offset? laidOutTopLeft(RenderBox box, {RenderObject? ancestor}) {
  if (!box.attached || !box.hasSize) return null;
  for (RenderObject? node = box.parent; node != null && !identical(node, ancestor); node = node.parent) {
    if (node is RenderBox && !node.hasSize) return null;
  }
  return box.localToGlobal(Offset.zero, ancestor: ancestor);
}

/// [box]'s rect, as [laidOutTopLeft] places it; null when it is not laid out.
Rect? laidOutRect(RenderBox box, {RenderObject? ancestor}) => switch (laidOutTopLeft(box, ancestor: ancestor)) {
  final topLeft? => topLeft & box.size,
  null => null,
};
