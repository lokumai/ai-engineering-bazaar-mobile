import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/caravan_journey.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_art.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_stage.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The Caravan's stage: the web's shadow play (C4), made for a finger.
///
/// The web moves the caravan with the page's scroll; a phone page scrolls up and down, so here the road moves on its
/// own. The caravan walks to the stop the reader chose ([selected]) and stands there; a drag sideways pulls the road
/// under the finger, and on release the caravan walks on to the nearest stop; a tap on a stall chooses it. Each choice
/// is reported through [onSelect].
///
/// The puppets move only while the caravan walks and for a few seconds after, then stand still until the next move,
/// so the stage draws nothing while the reader reads (and nothing at all under reduced motion, where the caravan is at
/// its stop at once). The picture is decoration: a screen reader hears [semanticLabel] and travels with the page's
/// buttons.
class CaravanStage extends StatefulWidget {
  const CaravanStage({
    super.key,
    required this.road,
    required this.journey,
    required this.selected,
    required this.onSelect,
    required this.semanticLabel,
  });

  final CaravanRoad road;
  final CaravanJourney journey;
  final int selected;
  final ValueChanged<int> onSelect;
  final String semanticLabel;

  /// How long the puppets keep rocking after the caravan stops.
  static const Duration idle = Duration(seconds: 6);

  @override
  State<CaravanStage> createState() => _CaravanStageState();
}

class _CaravanStageState extends State<CaravanStage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _clock = ValueNotifier(0);
  Duration _last = Duration.zero;
  Duration _restAt = Duration.zero;
  bool _dragging = false;
  Duration? _dragStamp;

  StageArt? _art;
  List<StopLabel>? _labels;
  ({Size size, CaravanRoad road, bool mirrored})? _artKey;
  ({CaravanRoad road, TextDirection direction, double width})? _labelKey;

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    widget.journey.addListener(_onJourney);
  }

  @override
  void didUpdateWidget(CaravanStage old) {
    super.didUpdateWidget(old);
    if (old.journey != widget.journey) {
      old.journey.removeListener(_onJourney);
      widget.journey.addListener(_onJourney);
    }
    if (old.selected != widget.selected || old.road != widget.road) _walkToSelected();
  }

  @override
  void dispose() {
    widget.journey.removeListener(_onJourney);
    _ticker.dispose();
    _clock.dispose();
    _art?.dispose();
    for (final label in _labels ?? const <StopLabel>[]) {
      label.dispose();
    }
    super.dispose();
  }

  StageGeometry? get _geometry => _art?.geometry;

  void _walkToSelected({bool instant = false}) {
    final geo = _geometry;
    if (geo == null || widget.selected < 0 || widget.selected >= widget.road.stops.length) return;
    widget.journey.walkTo(geo.cameraFor(widget.road.stops[widget.selected].at), instant: instant || _reduced);
  }

  void _onJourney() {
    if (!_ticker.isActive && (widget.journey.moving || widget.journey.velocity != 0)) _kick();
  }

  void _kick() {
    if (_reduced) {
      // Nothing walks: the stage is drawn where the journey is, once.
      widget.journey.step(0, reduced: true);
      return;
    }
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    _restAt = Duration.zero;
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final journey = widget.journey;
    if (!_dragging) journey.step(dt.clamp(0, 0.12).toDouble());
    _clock.value += dt.clamp(0, 0.12);
    if (journey.moving || _dragging) {
      _restAt = Duration.zero;
    } else {
      if (_restAt == Duration.zero) _restAt = elapsed + CaravanStage.idle;
      if (elapsed >= _restAt) {
        _ticker.stop();
        journey.rest();
      }
    }
  }

  // ---- the finger -------------------------------------------------------------------------------------------------

  (double, double) _bounds(StageGeometry geo) {
    final stops = widget.road.stops;
    if (stops.isEmpty) return (0, widget.road.length.toDouble());
    return (geo.cameraFor(stops.first.at) - 0.6, geo.cameraFor(stops.last.at) + 0.6);
  }

  bool get _mirrored => Directionality.of(context) == TextDirection.rtl;

  void _dragStart(DragStartDetails details) {
    _dragging = true;
    _dragStamp = details.sourceTimeStamp;
    _kick();
  }

  void _dragUpdate(DragUpdateDetails details) {
    final geo = _geometry;
    if (geo == null) return;
    final dx = _mirrored ? -details.delta.dx : details.delta.dx;
    final (lo, hi) = _bounds(geo);
    final stamp = details.sourceTimeStamp;
    final dt = stamp != null && _dragStamp != null ? (stamp - _dragStamp!).inMicroseconds / 1e6 : 1 / 60;
    _dragStamp = stamp;
    widget.journey.dragTo((widget.journey.t - dx / geo.month).clamp(lo, hi), dt: dt);
  }

  void _dragEnd(DragEndDetails details) {
    _dragging = false;
    final geo = _geometry;
    if (geo == null) return;
    final vx = _mirrored ? -details.velocity.pixelsPerSecond.dx : details.velocity.pixelsPerSecond.dx;
    // A flick carries the road a little further, then the caravan walks to the nearest stop there.
    final glide = widget.journey.t - vx / geo.month * 0.28;
    final stop = widget.road.nearestStop(glide + (StageGeometry.focus - 0.5) * geo.span);
    if (stop < 0) return;
    widget.journey.walkTo(geo.cameraFor(widget.road.stops[stop].at), instant: _reduced);
    _kick();
    widget.onSelect(stop);
  }

  void _tapUp(TapUpDetails details) {
    final geo = _geometry;
    if (geo == null) return;
    final camX = geo.cameraX(widget.journey.t);
    final tap = details.localPosition;
    final x = _mirrored ? geo.size.width - tap.dx : tap.dx;
    int? best;
    var distance = double.infinity;
    for (final stop in widget.road.stops) {
      final xw = stop.at * geo.month;
      final sx = xw - camX;
      final ground = geo.ground(xw);
      final piece = propOf(stop.index, stop.trend.peak);
      final half = (piece.top.abs() * 0.75 + 24) * geo.prop;
      final hit = Rect.fromLTRB(sx - half, ground + piece.top * geo.prop - 34, sx + half, ground + 30 * geo.g);
      if (!hit.contains(Offset(x, tap.dy))) continue;
      final d = (sx - x).abs();
      if (d < distance) {
        distance = d;
        best = stop.index;
      }
    }
    if (best == null) return;
    widget.journey.walkTo(geo.cameraFor(widget.road.stops[best].at), instant: _reduced);
    _kick();
    widget.onSelect(best);
  }

  // ---- the picture ------------------------------------------------------------------------------------------------

  void _prepare(Size size, TextDirection direction) {
    final mirrored = direction == TextDirection.rtl;
    final key = (size: size, road: widget.road, mirrored: mirrored);
    if (_artKey != key) {
      _art?.dispose();
      final geo = StageGeometry(size, widget.road);
      _art = StageArt(geo, mirrored: mirrored);
      _artKey = key;
      // A new size or road puts the caravan at its stop at once. This runs during layout, so the journey is told
      // quietly and its listeners (the strip) hear of it after the frame.
      if (widget.selected >= 0 && widget.selected < widget.road.stops.length) {
        widget.journey.place(geo.cameraFor(widget.road.stops[widget.selected].at));
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.journey.announce();
        });
      }
    }
    final width = size.width * 0.8;
    final labelKey = (road: widget.road, direction: direction, width: width);
    if (_labelKey != labelKey) {
      for (final label in _labels ?? const <StopLabel>[]) {
        label.dispose();
      }
      final style = DefaultTextStyle.of(context).style;
      _labels = [
        for (final stop in widget.road.stops)
          StopLabel(stop.trend.title, maxWidth: width, textDirection: direction, style: style),
      ];
      _labelKey = labelKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return Semantics(
      container: true,
      image: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            _prepare(size, direction);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _dragStart,
              onHorizontalDragUpdate: _dragUpdate,
              onHorizontalDragEnd: _dragEnd,
              onHorizontalDragCancel: () => _dragging = false,
              onTapUp: _tapUp,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: ShadowStagePainter(
                    art: _art!,
                    journey: widget.journey,
                    clock: _clock,
                    selected: widget.selected,
                    labels: _labels!,
                    mirrored: direction == TextDirection.rtl,
                    reduced: _reduced,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
