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
/// On a first run, once Welcome is over, the Apprentice comes onto Home and asks whether to show the reader around.
/// Said yes, the page dims but for one place at a time, and the Apprentice walks to it and says in a bubble what it is,
/// with Next and Skip and how far along it is; each tab's first page is shown the first time it is opened, until the
/// reader has seen it or skipped it. Settings' guide takes the tour again.
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

  /// The robot's width and height.
  static const double robotSize = 58;

  /// How long a page is left to settle, its content read and laid out, before the tour points into it.
  static const Duration settle = Duration(milliseconds: 600);

  /// How long the Apprentice takes to walk from one place to the next.
  static const Duration walk = Duration(milliseconds: 650);

  @override
  State<TourLayer> createState() => _TourLayerState();
}

class _TourLayerState extends State<TourLayer> {
  final _layer = GlobalKey();

  /// The page being shown, and the places on it to point at, in order.
  TourPage? _page;
  List<String> _spots = const [];
  int _step = 0;

  /// The place pointed at, in the layer's coordinates; null while the Apprentice is on its way.
  Rect? _hole;

  /// Where the robot stands; null before it first comes on.
  Offset? _robotAt;

  Timer? _settling;

  @override
  void dispose() {
    _settling?.cancel();
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
    _page = null;
    _spots = const [];
    _hole = null;
    _robotAt = null;
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
        return;
      }
      setState(() {
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
    final layer = _layer.currentContext?.findRenderObject() as RenderBox?;
    final box = target.findRenderObject() as RenderBox?;
    if (layer == null || box == null || !box.hasSize) return _next();
    final topLeft = box.localToGlobal(Offset.zero, ancestor: layer);
    final whole = Offset.zero & layer.size;
    final hole = (topLeft & box.size).intersect(whole);
    if (hole.isEmpty) return _next();
    setState(() {
      _hole = hole;
      _robotAt ??= _start(layer.size);
    });
    // The robot comes on where it stands, then walks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hole == hole) setState(() => _robotAt = _stand(hole, layer.size));
    });
  }

  /// Keeps the hole on its place when the page moves under it, as when the day's card comes in above it.
  void _follow() {
    final hole = _hole;
    if (!mounted || _page == null || hole == null) return;
    final target = TourTarget.contextOf(_spots[_step]);
    final layer = _layer.currentContext?.findRenderObject() as RenderBox?;
    final box = target?.findRenderObject() as RenderBox?;
    if (layer == null || box == null || !box.attached || !box.hasSize) return;
    final now = (box.localToGlobal(Offset.zero, ancestor: layer) & box.size).intersect(Offset.zero & layer.size);
    final moved = (now.topLeft - hole.topLeft).distance + (now.bottomRight - hole.bottomRight).distance;
    if (now.isEmpty || moved < 0.5) return;
    setState(() {
      _hole = now;
      _robotAt = _stand(now, layer.size);
    });
  }

  /// Where the robot first comes on: the corner of the floating button, over the navigation.
  Offset _start(Size size) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final y = size.height - 160;
    return Offset(rtl ? 16 : size.width - TourLayer.robotSize - 16, y);
  }

  /// Where the robot stands beside [hole]: on its lower edge when the bubble goes under it, on its upper edge when
  /// the bubble goes over it, at its start side.
  Offset _stand(Rect hole, Size size) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final double x = (rtl ? hole.right - 8 - TourLayer.robotSize : hole.left + 8).clamp(
      16.0,
      math.max(16.0, size.width - TourLayer.robotSize - 16),
    );
    final double y = switch (_side(hole, size)) {
      _Side.below => hole.bottom - TourLayer.robotSize / 3,
      _Side.above => hole.top - TourLayer.robotSize * 2 / 3,
      _Side.over => size.height - 16 - _overBubble - TourLayer.robotSize * 2 / 3,
    };
    return Offset(x, y.clamp(8.0, math.max(8.0, size.height - TourLayer.robotSize - 8)));
  }

  /// The room the bubble is given under or over a place, at the most.
  static const double _bubbleRoom = 220;

  /// About how tall a bubble is, for the robot to stand on it when it lies over the foot of a place filling the screen.
  static const double _overBubble = 150;

  static _Side _side(Rect hole, Size size) {
    if (size.height - hole.bottom >= _bubbleRoom + TourLayer.robotSize / 2) return _Side.below;
    if (hole.top >= _bubbleRoom + TourLayer.robotSize) return _Side.above;
    return _Side.over;
  }

  void _next() {
    final page = _page;
    if (page == null) return;
    if (_step + 1 >= _spots.length) {
      _finish();
      return;
    }
    setState(() => _step++);
    unawaited(_point());
  }

  void _finish() {
    final page = _page;
    setState(_stop);
    if (page != null) unawaited(context.read<TourCubit>().shown(page));
  }

  @override
  Widget build(BuildContext context) {
    final record = context.watch<TourCubit>().state;
    final asking = (record?.asking ?? false) && widget.location == BazaarPaths.home;
    final page = TourPage.at(widget.location);
    if (!asking && page != null && _page == null && context.read<TourCubit>().due(page)) _schedule(page);
    final showing = _page != null;
    if (showing && _hole != null) WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    return Stack(
      key: _layer,
      children: [
        // While the Apprentice speaks, a screen reader hears it alone.
        ExcludeSemantics(excluding: asking || showing, child: widget.child),
        if (asking)
          Positioned.fill(child: _Asking(robot: widget.robot))
        else if (showing)
          Positioned.fill(child: BlockSemantics(child: _pointing(context))),
      ],
    );
  }

  Widget _pointing(BuildContext context) {
    final s = S.of(context);
    final hole = _hole;
    final robotAt = _robotAt;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final last = _step + 1 >= _spots.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final side = hole == null ? _Side.over : _side(hole, size);
        final bubble = _Bubble(
          key: ValueKey(_spots[_step]),
          text: _textOf(s, _spots[_step]),
          counter: s.tour_step(_step + 1, _spots.length),
          actions: [
            TextButton(key: const ValueKey('tour-skip'), onPressed: _finish, child: Text(s.tour_skip)),
            FilledButton(
              key: const ValueKey('tour-next'),
              onPressed: _next,
              child: Text(last ? s.tour_done : s.tour_next),
            ),
          ],
        );
        final width = math.min(size.width - 32, 440.0);
        return Stack(
          children: [
            Positioned.fill(child: _Scrim(hole: hole)),
            if (hole != null && robotAt != null)
              Positioned(
                left: (size.width - width) / 2,
                width: width,
                top: switch (side) {
                  _Side.below => hole.bottom + TourLayer.robotSize * 2 / 3 + 4,
                  _ => null,
                },
                bottom: switch (side) {
                  _Side.below => null,
                  _Side.above => size.height - hole.top + TourLayer.robotSize * 2 / 3 + 4,
                  _Side.over => 16,
                },
                child: bubble,
              ),
            if (robotAt != null)
              AnimatedPositioned(
                duration: reduced ? Duration.zero : TourLayer.walk,
                curve: Curves.easeInOut,
                left: robotAt.dx,
                top: robotAt.dy,
                width: TourLayer.robotSize,
                height: TourLayer.robotSize,
                child: _Hop(key: ValueKey((_step, robotAt)), hop: !reduced, child: widget.robot),
              ),
          ],
        );
      },
    );
  }

  static String _textOf(S s, String spot) => switch (spot) {
    TourSpots.homeHead => s.tour_home_head,
    TourSpots.homeAfter => s.tour_home_after,
    TourSpots.band => s.tour_band,
    TourSpots.tabs => s.tour_tabs,
    TourSpots.catalogSearch => s.tour_catalog_search,
    TourSpots.catalogLevels => s.tour_catalog_levels,
    TourSpots.caravanStage => s.tour_caravan_stage,
    TourSpots.caravanStrip => s.tour_caravan_strip,
    TourSpots.quizLevel => s.tour_quiz_level,
    TourSpots.settingsReading => s.tour_settings_reading,
    TourSpots.settingsGuide => s.tour_settings_guide,
    _ => '',
  };
}

/// Where a place's bubble goes: under it, over it, or over its foot when it fills the screen.
enum _Side { below, above, over }

/// The Apprentice's question on a first run's Home: the page dims, it comes on in the middle and asks.
class _Asking extends StatelessWidget {
  const _Asking({required this.robot});

  final Widget robot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<TourCubit>();
    final reduced = MediaQuery.disableAnimationsOf(context);
    return BlockSemantics(
      child: Stack(
        children: [
          const Positioned.fill(child: _Scrim(hole: null)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: SizedBox.square(
                        dimension: TourLayer.robotSize,
                        child: _Hop(hop: !reduced, child: robot),
                      ),
                    ),
                    _Bubble(
                      key: const ValueKey('tour-asking'),
                      text: s.tour_hello,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the Apprentice says, with what the reader can answer.
class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.text, required this.actions, this.counter});

  final String text;
  final List<Widget> actions;

  /// How far along the page's places it is, as `1 / 4`.
  final String? counter;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final counter = this.counter;
    return Material(
      color: colors.surfaceRaised,
      elevation: 6,
      shadowColor: const Color(0x66000000),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(text, style: textTheme.bodyMedium?.copyWith(color: colors.onSurface)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (counter != null) Text(counter, style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted)),
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

/// The page dimmed, but for [hole]; it takes every touch, so the page waits while the Apprentice speaks.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.hole});

  final Rect? hole;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: ExcludeSemantics(
        child: CustomPaint(key: const ValueKey('tour-scrim'), painter: _ScrimPainter(hole)),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (hole case final hole?) {
      path.addRRect(RRect.fromRectAndRadius(hole.inflate(6), const Radius.circular(14)));
    }
    canvas.drawPath(path, Paint()..color = const Color(0x8C000000));
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
