import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/tour/application/tour_cubit.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_page.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Apprentice's tour over the app (plan 11.3, the owner, 2026-11-16), which the app lays over its shell.
///
/// On a first run, once Welcome is over, the Apprentice comes out of its floating button onto Home and asks whether to
/// show the reader around. Said yes, the page dims but for one place at a time, ringed in gold, and the Apprentice
/// walks to it and says in a speech bubble what it is, with Next and Skip and dots for how far along it is; each tab's
/// first page is shown the first time it is opened. Skip ends the whole tour; Settings' guide takes it again. Done, the
/// Apprentice walks back into its button, which is left empty while it is out ([TourRobotOut]).
///
/// The places are the [TourTarget]s the pages mark, found by name, so no feature imports another; one not on the
/// screen, such as the band with every module completed, is passed over.
class TourLayer extends StatefulWidget {
  const TourLayer({super.key, required this.location, required this.robot, required this.child});

  /// The path of the page in front.
  final String location;

  /// The Apprentice as it walks, which the app draws: the tour feature does not import it.
  final Widget robot;
  final Widget child;

  /// The robot's width and height, its floating button's.
  static const double robotSize = 58;

  /// How long a page is left to settle, its content read and laid out, before the tour points into it.
  static const Duration settle = Duration(milliseconds: 600);

  /// How long the Apprentice takes to walk from one place to the next.
  static const Duration walk = Duration(milliseconds: 650);

  /// The share of the screen's height at its foot that no bubble goes into.
  static const double overFoot = 0.22;

  /// The gap between the robot and its bubble, which the bubble's tail crosses.
  static const double bubbleGap = 12;

  @override
  State<TourLayer> createState() => _TourLayerState();
}

class _TourLayerState extends State<TourLayer> {
  final _layer = GlobalKey();

  /// Where the robot stands while it asks, in the question's column.
  final _seat = GlobalKey();

  /// The bubble, for the robot to stand on it when it lies over the foot of a place filling the screen.
  final _bubble = GlobalKey();

  /// The page being shown, and the places on it to point at, in order.
  TourPage? _page;
  List<String> _spots = const [];
  int _step = 0;

  /// The place pointed at, in the layer's coordinates; null while the Apprentice is on its way.
  Rect? _hole;

  /// Where the robot stands; null while it is in its button.
  Offset? _robotAt;

  /// Whether the robot is walking back into its button.
  bool _leaving = false;

  /// Whether the question was up at the last build, to tell when it is answered.
  bool _wasAsking = false;

  Timer? _settling;
  Timer? _home;

  @override
  void dispose() {
    _settling?.cancel();
    _home?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TourLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another page in front: what was being shown is left for when it is opened again.
    if (oldWidget.location != widget.location) _stop();
  }

  void _stop() {
    _settling?.cancel();
    _settling = null;
    _home?.cancel();
    _home = null;
    _page = null;
    _spots = const [];
    _hole = null;
    _robotAt = null;
    _leaving = false;
  }

  RenderBox? get _layerBox => _layer.currentContext?.findRenderObject() as RenderBox?;

  /// The rect of [context]'s box in the layer, if it is laid out.
  Rect? _rectOf(BuildContext? context) {
    final layer = _layerBox;
    final box = context?.findRenderObject() as RenderBox?;
    if (layer == null || box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: layer) & box.size;
  }

  /// Where the robot's button is: where it comes out of and goes back into. With the button hidden in Settings, or on
  /// a page without it, the corner the button stands in at first.
  Offset _button(Size size) {
    if (_rectOf(TourTarget.contextOf(TourSpots.assistant)) case final rect?) return rect.topLeft;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Offset(rtl ? 16 : size.width - TourLayer.robotSize - 16, size.height - 160);
  }

  /// The robot comes out of its button and walks to where [to] says, a frame later so it is seen to walk.
  void _comeOut(Offset? Function(Size size) to) {
    final layer = _layerBox;
    if (layer == null) return;
    setState(() => _robotAt = _button(layer.size));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _leaving) return;
      if (to(layer.size) case final at?) setState(() => _robotAt = at);
    });
  }

  /// The robot walks back into its button; there, the button is drawn again.
  void _leave() {
    final layer = _layerBox;
    setState(() {
      _settling?.cancel();
      _settling = null;
      _page = null;
      _spots = const [];
      _hole = null;
      if (_robotAt == null || layer == null) return;
      _leaving = true;
      _robotAt = _button(layer.size);
    });
    if (!_leaving) return;
    _home?.cancel();
    _home = Timer(MediaQuery.disableAnimationsOf(context) ? Duration.zero : TourLayer.walk, () {
      if (!mounted) return;
      setState(() {
        _home = null;
        _leaving = false;
        _robotAt = null;
      });
    });
  }

  /// The question was answered: said yes, the robot waits where it is for Home to settle; said no, it goes back.
  void _answered() {
    if (!mounted) return;
    if (context.read<TourCubit>().state?.guiding ?? false) return;
    _leave();
  }

  /// Shows [page] once it has settled, if it is still due then.
  void _schedule(TourPage page) {
    if (_page != null || _settling != null) return;
    _settling = Timer(TourLayer.settle, () {
      _settling = null;
      if (!mounted || TourPage.at(widget.location) != page || !context.read<TourCubit>().due(page)) return;
      final spots = [
        for (final spot in page.spots)
          if (TourTarget.contextOf(spot) != null) spot,
      ];
      if (spots.isEmpty) {
        unawaited(context.read<TourCubit>().shown(page));
        if (_robotAt != null) _leave();
        return;
      }
      _home?.cancel();
      setState(() {
        _home = null;
        _leaving = false;
        _page = page;
        _spots = spots;
        _step = 0;
      });
      unawaited(_point());
    });
  }

  /// Brings the place of this step into view and walks the Apprentice to it.
  Future<void> _point() async {
    final page = _page;
    if (page == null) return;
    final target = TourTarget.contextOf(_spots[_step]);
    if (target == null) return _next();
    setState(() => _hole = null);
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (Scrollable.maybeOf(target) != null) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 300),
      );
    }
    if (!mounted || _page != page || !target.mounted) return;
    final layer = _layerBox;
    final rect = _rectOf(target);
    if (layer == null || rect == null) return _next();
    final hole = rect.intersect(Offset.zero & layer.size);
    if (hole.isEmpty) return _next();
    setState(() => _hole = hole);
    if (_robotAt == null) {
      _comeOut((size) => _hole == hole ? _stand(hole, size) : null);
    } else {
      setState(() => _robotAt = _stand(hole, layer.size));
    }
  }

  /// Keeps the hole on its place when the page moves under it, as when the day's card comes in above it, and the robot
  /// on its bubble when the bubble lies over the place.
  void _follow() {
    final hole = _hole;
    if (!mounted || _page == null || hole == null) return;
    final layer = _layerBox;
    final rect = _rectOf(TourTarget.contextOf(_spots[_step]));
    if (layer == null || rect == null) return;
    final now = rect.intersect(Offset.zero & layer.size);
    final moved = (now.topLeft - hole.topLeft).distance + (now.bottomRight - hole.bottomRight).distance;
    if (!now.isEmpty && moved >= 0.5) {
      setState(() {
        _hole = now;
        _robotAt = _stand(now, layer.size);
      });
      return;
    }
    if (_side(hole, layer.size) != _Side.over) return;
    final at = _robotAt;
    final bubble = _rectOf(_bubble.currentContext);
    if (at == null || bubble == null) return;
    final y = bubble.top - TourLayer.bubbleGap - TourLayer.robotSize;
    if ((at.dy - y).abs() >= 0.5) setState(() => _robotAt = Offset(at.dx, y));
  }

  /// How much of the robot stands over the place it points at: its foot or its head, little of the place hidden.
  static const double _perch = TourLayer.robotSize / 5;

  /// Where the robot stands beside [hole]: on its lower edge when the bubble goes under it, on its upper edge when
  /// the bubble goes over it, at its start side; at its end side on Home's head, where the whole robot already stands
  /// at the start, so the two are not stacked.
  Offset _stand(Rect hole, Size size) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final atStart = _step >= _spots.length || _spots[_step] != TourSpots.homeHead;
    final double x = (rtl == atStart ? hole.right - 8 - TourLayer.robotSize : hole.left + 8).clamp(
      16.0,
      math.max(16.0, size.width - TourLayer.robotSize - 16),
    );
    final double y = switch (_side(hole, size)) {
      _Side.below => hole.bottom - _perch,
      _Side.above => hole.top - TourLayer.robotSize + _perch,
      _Side.over => size.height - _overFoot(size) - _overBubble - TourLayer.bubbleGap - TourLayer.robotSize,
    };
    return Offset(x, y.clamp(8.0, math.max(8.0, size.height - TourLayer.robotSize - 8)));
  }

  /// Where the robot stands while it asks: on its seat in the question's column.
  Offset? _seated(Size size) => _rectOf(_seat.currentContext)?.topLeft;

  /// The room the bubble is given under or over a place, at the most.
  static const double _bubbleRoom = 230;

  /// About how tall a bubble is, for where the robot first heads when the bubble lies over the foot of a place filling
  /// the screen; [_follow] then stands it on the bubble as laid out.
  static const double _overBubble = 170;

  /// The screen's foot no bubble goes into: its lowest fifth or so, the band and the navigation, so Next is never at
  /// the screen's very foot (the owner, 2026-11-16: on the catalog's levels it lay on the navigation). A bubble under a
  /// place needs its room above it; one over a place filling the screen stands on it.
  static double _overFoot(Size size) => math.max(16, size.height * TourLayer.overFoot);

  static _Side _side(Rect hole, Size size) {
    if (size.height - _overFoot(size) - hole.bottom >= _bubbleRoom + TourLayer.robotSize - _perch) return _Side.below;
    if (hole.top >= _bubbleRoom + TourLayer.robotSize - _perch) return _Side.above;
    return _Side.over;
  }

  void _next() {
    final page = _page;
    if (page == null) return;
    if (_step + 1 >= _spots.length) {
      unawaited(context.read<TourCubit>().shown(page));
      _leave();
      return;
    }
    setState(() => _step++);
    unawaited(_point());
  }

  /// Skip: the tour ends, on every tab (the owner, 2026-11-16).
  void _skip() {
    unawaited(context.read<TourCubit>().end());
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final record = context.watch<TourCubit>().state;
    final asking = (record?.asking ?? false) && widget.location == BazaarPaths.home;
    if (asking && _robotAt == null && !_leaving) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _robotAt == null) _comeOut(_seated);
      });
    }
    if (_wasAsking && !asking) WidgetsBinding.instance.addPostFrameCallback((_) => _answered());
    _wasAsking = asking;
    final page = TourPage.at(widget.location);
    if (!asking && page != null && _page == null && context.read<TourCubit>().due(page)) _schedule(page);
    final showing = _page != null;
    // A new size (a tablet turned, a window resized) lays the place out again, so the ring is measured again with it.
    MediaQuery.sizeOf(context);
    if (showing && _hole != null) WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    // The robot is out, between its question and the first place, or walking home: the page still waits for it.
    final waiting = !asking && !showing && _robotAt != null && !_leaving;
    final robotAt = _robotAt;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Stack(
      key: _layer,
      children: [
        // While the Apprentice speaks, a screen reader hears it alone; while it is out, its button is empty.
        TourRobotOut(
          out: asking || robotAt != null,
          child: ExcludeSemantics(excluding: asking || showing, child: widget.child),
        ),
        if (asking)
          Positioned.fill(child: _Asking(seat: _seat))
        else if (showing)
          Positioned.fill(child: BlockSemantics(child: _pointing(context)))
        else if (waiting)
          const Positioned.fill(child: _Scrim(hole: null)),
        if (robotAt != null)
          AnimatedPositioned(
            duration: reduced ? Duration.zero : TourLayer.walk,
            curve: Curves.easeInOut,
            left: robotAt.dx,
            top: robotAt.dy,
            width: TourLayer.robotSize,
            height: TourLayer.robotSize,
            child: _Hop(key: ValueKey(robotAt), hop: !reduced, child: widget.robot),
          ),
      ],
    );
  }

  Widget _pointing(BuildContext context) {
    final s = S.of(context);
    final hole = _hole;
    final robotAt = _robotAt;
    final last = _step + 1 >= _spots.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final side = hole == null ? _Side.over : _side(hole, size);
        final width = math.min(size.width - 32, 440.0);
        final left = (size.width - width) / 2;
        final gap = TourLayer.robotSize - _perch + TourLayer.bubbleGap;
        return Stack(
          children: [
            Positioned.fill(child: _Scrim(hole: hole)),
            if (hole != null && robotAt != null)
              Positioned(
                left: left,
                width: width,
                top: switch (side) {
                  _Side.below => hole.bottom + gap,
                  _ => null,
                },
                bottom: switch (side) {
                  _Side.below => null,
                  _Side.above => size.height - hole.top + gap,
                  _Side.over => _overFoot(size),
                },
                child: _Bubble(
                  key: _bubble,
                  text: _textOf(s, _spots[_step]),
                  step: _step,
                  steps: _spots.length,
                  // The tail reaches for the robot, under it or over it.
                  tailX: robotAt.dx + TourLayer.robotSize / 2 - left,
                  tailUp: side != _Side.above,
                  actions: [
                    TextButton(key: const ValueKey('tour-skip'), onPressed: _skip, child: Text(s.tour_skip)),
                    FilledButton.icon(
                      key: const ValueKey('tour-next'),
                      onPressed: _next,
                      iconAlignment: IconAlignment.end,
                      icon: Icon(last ? Icons.check : Icons.arrow_forward, size: 18),
                      label: Text(last ? s.tour_done : s.tour_next),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static String _textOf(S s, String spot) => switch (spot) {
    TourSpots.homeHead => s.tour_home_head,
    TourSpots.homePractice => s.tour_home_practice,
    TourSpots.homeAfter => s.tour_home_after,
    TourSpots.band => s.tour_band,
    TourSpots.tabs => s.tour_tabs,
    TourSpots.catalogSearch => s.tour_catalog_search,
    TourSpots.catalogLevels => s.tour_catalog_levels,
    TourSpots.caravanStage => s.tour_caravan_stage,
    TourSpots.caravanStrip => s.tour_caravan_strip,
    TourSpots.practiceToday => s.tour_practice_today,
    TourSpots.quizLevel => s.tour_quiz_level,
    TourSpots.settingsReading => s.tour_settings_reading,
    TourSpots.settingsCustomize => s.tour_settings_customize,
    TourSpots.settingsGuide => s.tour_settings_guide,
    _ => '',
  };
}

/// Where a place's bubble goes: under it, over it, or over its foot when it fills the screen.
enum _Side { below, above, over }

/// The gold the places are ringed in, the Apprentice's badge's.
const _gold = Color(0xffddb46a);

/// The Apprentice's question on a first run's Home: the page dims, it comes out onto its [seat] in the middle and asks.
class _Asking extends StatelessWidget {
  const _Asking({required this.seat});

  final GlobalKey seat;

  /// How far the seat is from the bubble's start edge.
  static const double _inset = 12;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<TourCubit>();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return BlockSemantics(
      child: Stack(
        children: [
          const Positioned.fill(child: _Scrim(hole: null)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final middle = _inset + TourLayer.robotSize / 2;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: _inset, bottom: TourLayer.bubbleGap),
                          child: SizedBox.square(key: seat, dimension: TourLayer.robotSize),
                        ),
                        _Bubble(
                          key: const ValueKey('tour-asking'),
                          text: s.tour_hello,
                          tailX: rtl ? constraints.maxWidth - middle : middle,
                          tailUp: true,
                          actions: [
                            TextButton(
                              key: const ValueKey('tour-later'),
                              onPressed: cubit.decline,
                              child: Text(s.tour_later),
                            ),
                            FilledButton(
                              key: const ValueKey('tour-accept'),
                              onPressed: cubit.accept,
                              child: Text(s.tour_show_me),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the Apprentice says, in a speech bubble whose tail reaches for it, with its name, what the reader can answer
/// and, on a page's places, a dot for each.
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.text,
    required this.actions,
    required this.tailX,
    required this.tailUp,
    this.step,
    this.steps,
  });

  final String text;
  final List<Widget> actions;

  /// Where the tail leaves the bubble, from its left edge, and whether it points up.
  final double tailX;
  final bool tailUp;

  /// The place being shown and how many the page has; no dots while null.
  final int? step;
  final int? steps;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final (step, steps) = (this.step, this.steps);
    return Material(
      color: colors.surfaceRaised,
      elevation: 3,
      shadowColor: const Color(0x40000000),
      shape: _BubbleShape(
        tailX: tailX,
        up: tailUp,
        side: BorderSide(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Text(s.pocket_title, style: displayFace(textTheme.titleSmall)?.copyWith(color: colors.primary)),
            ),
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              child: Text(text, style: textTheme.bodyLarge?.copyWith(color: colors.onSurface, height: 1.4)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (step != null && steps != null) _Dots(step: step, steps: steps),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A dot for each of a page's places, the one shown long and filled; a screen reader hears `2 / 4`.
class _Dots extends StatelessWidget {
  const _Dots({required this.step, required this.steps});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: S.of(context).tour_step(step + 1, steps),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          for (var i = 0; i < steps; i++)
            AnimatedContainer(
              duration: reduced ? Duration.zero : const Duration(milliseconds: 250),
              width: i == step ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i <= step ? colors.primary : colors.line,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A rounded bubble with a tail at [tailX] from its left edge, up out of its top or down out of its foot.
class _BubbleShape extends ShapeBorder {
  const _BubbleShape({required this.tailX, required this.up, this.side = BorderSide.none});

  final double tailX;
  final bool up;
  final BorderSide side;

  static const double _radius = 18;
  static const double _tail = 11;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  Path _path(Rect rect) {
    final x = (rect.left + tailX).clamp(
      rect.left + _radius + _tail,
      math.max(rect.left + _radius + _tail, rect.right - _radius - _tail),
    );
    final edge = up ? rect.top : rect.bottom;
    final tip = up ? edge - _tail : edge + _tail;
    // The tip leans a little toward the start, as a drawn bubble's does.
    final tail = Path()
      ..moveTo(x - _tail, edge)
      ..quadraticBezierTo(x - 2, edge, x - 3, tip)
      ..quadraticBezierTo(x + 3, edge, x + _tail, edge)
      ..close();
    return Path.combine(
      PathOperation.union,
      Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(_radius))),
      tail,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => _BubbleShape(tailX: tailX * t, up: up, side: side.scale(t));
}

/// The page dimmed, but for [hole], which a gold ring breathes around; it takes every touch, so the page waits while
/// the Apprentice speaks.
class _Scrim extends StatefulWidget {
  const _Scrim({required this.hole});

  final Rect? hole;

  @override
  State<_Scrim> createState() => _ScrimState();
}

class _ScrimState extends State<_Scrim> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath
        ..stop()
        ..value = 1;
    } else if (!_breath.isAnimating) {
      unawaited(_breath.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: ExcludeSemantics(
        child: CustomPaint(key: const ValueKey('tour-scrim'), painter: _ScrimPainter(widget.hole, _breath)),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.hole, this.breath) : super(repaint: breath);

  final Rect? hole;
  final Animation<double> breath;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    final hole = this.hole;
    final ring = hole == null ? null : RRect.fromRectAndRadius(hole.inflate(6), const Radius.circular(14));
    if (ring != null) path.addRRect(ring);
    canvas.drawPath(path, Paint()..color = const Color(0x99000000));
    if (ring == null) return;
    final t = Curves.easeInOut.transform(breath.value);
    canvas
      ..drawRRect(
        ring.inflate(2 + 3 * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = _gold.withValues(alpha: 0.12 + 0.18 * t),
      )
      ..drawRRect(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _gold.withValues(alpha: 0.7 + 0.3 * t),
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}

/// The robot's walk: a few little hops while it moves, none with reduced motion.
class _Hop extends StatelessWidget {
  const _Hop({super.key, required this.hop, required this.child});

  final bool hop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!hop) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: TourLayer.walk,
      builder: (context, t, child) =>
          Transform.translate(offset: Offset(0, -12 * (math.sin(t * 3 * math.pi)).abs()), child: child),
      child: child,
    );
  }
}
