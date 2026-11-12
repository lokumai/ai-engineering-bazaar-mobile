import 'dart:async';

import 'package:ai_engineering_bazaar/shared/content/domain/search_text.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The words searched in the catalog, found again in the module it opened (plan 7.1): every [InlineText] under a
/// [TextFindScope] marks the words that answer [terms] by the search's own rules, and the reader steps from one to the
/// next, as a browser's find in page does. The marks are counted in the order they are drawn down the page.
final class TextFinder extends ChangeNotifier {
  TextFinder({required String query, required this.lang})
    : terms = {...searchTerms(query, lang), ...searchTerms(joinedVariant(query, lang) ?? '', lang)}.toList(),
      query = query.trim();

  /// The words as typed.
  final String query;

  /// Told when a step moves the page to a mark.
  VoidCallback? onStep;
  final String lang;

  /// The words as matched; none finds nothing.
  final List<String> terms;

  /// The pieces of text that hold marks, with how many each holds.
  final _counts = <TextFindTarget, int>{};

  /// The mark the reader is on: a piece of text and the place of the mark in it.
  (TextFindTarget, int)? _current;

  bool _countScheduled = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  int _total = 0;

  /// How many marks the page holds.
  int get total => _total;

  /// The place of the current mark among all of them, from 1; 0 while there is none.
  int get position {
    final current = _current;
    if (current == null) return 0;
    final at = _ordered().indexWhere((mark) => mark.$1 == current.$1 && mark.$2 == current.$2);
    return at + 1;
  }

  /// Whether the mark [index] of [target] is the current one.
  bool isCurrent(TextFindTarget target, int index) => _current?.$1 == target && _current?.$2 == index;

  /// Records how many marks [target] holds, as it is drawn.
  void report(TextFindTarget target, int count) {
    if (count == 0) {
      if (_counts.remove(target) == null) return;
    } else {
      if (_counts[target] == count) return;
      _counts[target] = count;
    }
    _scheduleCount();
  }

  /// Forgets [target], gone from the page.
  void forget(TextFindTarget target) {
    if (_disposed || _counts.remove(target) == null) return;
    if (_current?.$1 == target) _current = null;
    _scheduleCount();
  }

  void _scheduleCount() {
    if (_countScheduled) return;
    _countScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _countScheduled = false;
      if (_disposed) return;
      final total = _counts.values.fold(0, (sum, count) => sum + count);
      if (total != _total) {
        _total = total;
        notifyListeners();
      }
    });
  }

  /// Every mark, top of the page first, and left to right within a line.
  List<(TextFindTarget, int)> _ordered() {
    final placed = <(Offset, TextFindTarget)>[];
    for (final target in _counts.keys) {
      final box = target.context.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      placed.add((box.localToGlobal(Offset.zero), target));
    }
    placed.sort((a, b) => a.$1.dy != b.$1.dy ? a.$1.dy.compareTo(b.$1.dy) : a.$1.dx.compareTo(b.$1.dx));
    return [
      for (final (_, target) in placed)
        for (var i = 0; i < _counts[target]!; i++) (target, i),
    ];
  }

  /// Makes the first mark at or below [top] (a global offset) the current one, without scrolling: the page already
  /// shows where it opened.
  void startAt(double top) {
    final marks = _ordered();
    if (marks.isEmpty) return;
    _current = marks.firstWhere(
      (mark) => (mark.$1.context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero).dy >= top - 1,
      orElse: () => marks.first,
    );
    notifyListeners();
  }

  /// Moves to the next mark, after the last one back to the first, and scrolls it into view.
  void next() => _step(1);

  /// Moves to the mark before, before the first one round to the last, and scrolls it into view.
  void previous() => _step(-1);

  void _step(int by) {
    final marks = _ordered();
    if (marks.isEmpty) return;
    final current = _current;
    final at = current == null ? -1 : marks.indexWhere((mark) => mark.$1 == current.$1 && mark.$2 == current.$2);
    final next = at < 0 ? (by > 0 ? 0 : marks.length - 1) : (at + by) % marks.length;
    _current = marks[next];
    onStep?.call();
    notifyListeners();
    unawaited(_show(marks[next]));
  }

  /// Scrolls the text holding [mark] into view, then, in a paragraph longer than the page, the mark itself.
  Future<void> _show((TextFindTarget, int) mark) async {
    final (target, index) = mark;
    final context = target.context;
    const duration = Duration(milliseconds: 200);
    final page = Scrollable.maybeOf(context, axis: Axis.vertical);
    await Scrollable.ensureVisible(context, alignment: 0.3, duration: duration);
    if (_disposed || page == null || !page.mounted) return;
    final rect = target.markRect(index);
    final view = page.context.findRenderObject();
    if (rect == null || view is! RenderBox || !view.attached) return;
    final top = view.localToGlobal(Offset.zero).dy;
    final height = view.size.height;
    if (rect.top >= top && rect.bottom <= top + height) return;
    final position = page.position;
    final to = (position.pixels + rect.top - (top + 0.3 * height)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await position.animateTo(to, duration: duration, curve: Curves.ease);
  }
}

/// A piece of text that may hold marks: an [InlineText]'s state.
abstract interface class TextFindTarget {
  BuildContext get context;

  /// Where the mark [index] of this text is drawn, in global coordinates; null when it is not laid out.
  Rect? markRect(int index);
}

/// Gives the [TextFinder] to the text under it; the text marks nothing without one, or under a scope with none.
class TextFindScope extends InheritedNotifier<TextFinder> {
  const TextFindScope({super.key, required TextFinder? finder, required super.child}) : super(notifier: finder);

  /// The finder above [context], if any, and the text rebuilt as it changes.
  static TextFinder? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TextFindScope>()?.notifier;
}
