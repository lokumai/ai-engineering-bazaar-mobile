import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A round button the reader can move (the pocket model's, plan 9.4): it starts in the corner at the page's foot, a
/// finger drags it anywhere over the page, and a flick throws it, so it slides, bounces off the page's edges and comes
/// to rest. With reduced motion it stays where the finger lets it go.
///
/// It fills the room it is given and takes touches only on its [child]. Where it rests is [at], the child's top-left
/// corner; null is the start corner. [onRest] hears each place it comes to rest, so the owner keeps it across pages.
class FloatingDock extends StatefulWidget {
  const FloatingDock({super.key, required this.size, required this.child, this.at, this.onRest, this.margin = 16});

  /// The child's width and height.
  final double size;
  final Widget child;
  final Offset? at;
  final ValueChanged<Offset>? onRest;

  /// The gap kept between the child and the page's edges.
  final double margin;

  /// How much of its speed a bounce keeps.
  static const double bounce = 0.62;

  /// How fast a throw slows: its speed falls by e to the power of this, each second.
  static const double friction = 3.4;

  /// Below this speed, in logical pixels a second, a throw is over.
  static const double rest = 30;

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Offset? _at;
  Offset _velocity = Offset.zero;
  Duration? _last;
  Size _room = Size.zero;

  @override
  void initState() {
    super.initState();
    _at = widget.at;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Rect get _bounds {
    final m = widget.margin;
    return Rect.fromLTRB(m, m, math.max(m, _room.width - widget.size - m), math.max(m, _room.height - widget.size - m));
  }

  Offset _start() {
    final b = _bounds;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Offset(rtl ? b.left : b.right, b.bottom);
  }

  Offset _clamp(Offset at) {
    final b = _bounds;
    return Offset(at.dx.clamp(b.left, b.right), at.dy.clamp(b.top, b.bottom));
  }

  void _onPanStart(DragStartDetails details) {
    _ticker.stop();
    _velocity = Offset.zero;
    _at = _clamp(_at ?? _start());
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _at = _clamp((_at ?? _start()) + details.delta));
  }

  void _onPanEnd(DragEndDetails details) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final thrown = details.velocity.pixelsPerSecond;
    if (reduced || thrown.distance < FloatingDock.rest * 4) {
      _settle();
      return;
    }
    // A wild flick is held to a speed the eye can follow.
    _velocity = thrown.distance > 5000 ? thrown / thrown.distance * 5000 : thrown;
    _last = null;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = _last == null ? 0.0 : (elapsed - _last!).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    final b = _bounds;
    var at = (_at ?? _start()) + _velocity * dt;
    var vx = _velocity.dx;
    var vy = _velocity.dy;
    // An edge reflects it, a little slower, as a ball off a wall.
    if (at.dx < b.left) {
      at = Offset(b.left + (b.left - at.dx) * FloatingDock.bounce, at.dy);
      vx = -vx * FloatingDock.bounce;
    } else if (at.dx > b.right) {
      at = Offset(b.right - (at.dx - b.right) * FloatingDock.bounce, at.dy);
      vx = -vx * FloatingDock.bounce;
    }
    if (at.dy < b.top) {
      at = Offset(at.dx, b.top + (b.top - at.dy) * FloatingDock.bounce);
      vy = -vy * FloatingDock.bounce;
    } else if (at.dy > b.bottom) {
      at = Offset(at.dx, b.bottom - (at.dy - b.bottom) * FloatingDock.bounce);
      vy = -vy * FloatingDock.bounce;
    }
    _velocity = Offset(vx, vy) * math.exp(-FloatingDock.friction * dt);
    setState(() => _at = _clamp(at));
    if (_velocity.distance < FloatingDock.rest) {
      _ticker.stop();
      _settle();
    }
  }

  void _settle() {
    _velocity = Offset.zero;
    final at = _at;
    if (at != null) widget.onRest?.call(at);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _room = constraints.biggest;
        final at = _clamp(_at ?? _start());
        return Stack(
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              width: widget.size,
              height: widget.size,
              child: GestureDetector(
                key: const ValueKey('floating-dock'),
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
