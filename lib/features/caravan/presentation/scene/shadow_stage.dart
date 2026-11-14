import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/caravan_journey.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_art.dart';
import 'package:flutter/widgets.dart';

/// The proportions of the shadow play on a phone (the web's `PHONE` in `scene/shadow.ts`), in pixels per unit of zoom.
abstract final class _Phone {
  /// One month across the road at zoom 1.
  static const month = 150.0;

  /// How far the upper band rises where the road is busiest.
  static const amp = 40.0;
  static const puppet = 0.5;
  static const prop = 0.5;
  static const post = 0.6;
  static const landmark = 0.36;
  static const band = 34.0;
  static const ledge = 22.0;
  static const walk = 12.0;
  static const walkRise = 8.0;

  /// The caravan's distance from the cloth's start edge.
  static const left = 18.0;
  static const ridge = 150.0;

  /// The width that allows zoom 1, and the largest zoom drawn.
  static const wide = 340.0;
  static const most = 1.15;
}

/// The frame's parts, in pixels.
abstract final class StageFrame {
  /// The valance's height, over the cloth's top edge.
  static const valance = 24.0;

  /// The wooden frame beside the cloth.
  static const side = 8.0;

  /// The room kept over the tallest prop for its name.
  static const label = 40.0;

  /// The gap between the tallest puppet and the land the stops stand on, where the road is flat.
  static const clear = 12.0;
}

/// Where everything stands on a stage of [size] for [road] (the web's `mountShadowPlay` measurements): the zoom [g]
/// that fits the whole scene, from the ledge to a name over the tallest prop, in the stage's height, and the two levels,
/// the props' band above and the caravan's road below.
final class StageGeometry {
  StageGeometry(this.size, this.road) : g = zoomFor(size) {
    month = _Phone.month * math.max(1, g);
    amp = _Phone.amp * g;
    puppet = _Phone.puppet * g;
    prop = _Phone.prop * g;
    post = _Phone.post * g;
    ledge = (_Phone.ledge * g).roundToDouble();
    base = size.height - ledge - (_Phone.walk - 4) * g - puppetHeight * puppet - StageFrame.clear;
  }

  final Size size;
  final CaravanRoad road;

  /// The zoom.
  final double g;
  late final double month;
  late final double amp;
  late final double puppet;
  late final double prop;
  late final double post;
  late final double ledge;

  /// The upper band where the road is flat.
  late final double base;

  /// Where a chosen stop stands across the stage: a little past the middle, so the caravan arrives just before it.
  static const focus = 0.64;

  /// The largest zoom at which the scene fits [size] (the web's `zoomFor`).
  static double zoomFor(Size size) {
    const span =
        _Phone.ledge + _Phone.walk - 4 + puppetHeight * _Phone.puppet + 1.05 * _Phone.amp + propHeight * _Phone.prop;
    final room = size.height - StageFrame.valance - StageFrame.label - StageFrame.clear;
    return (room / span).clamp(0.5, math.max(0.5, math.min(_Phone.most, size.width / _Phone.wide)));
  }

  /// The upper band, where the props stand, at [xw] pixels along the road.
  double ground(double xw) => base - road.heatAt(xw / month) * amp;

  /// The lower road, where the caravan walks, just above the ledge.
  double walk(double xw) => size.height - ledge - (_Phone.walk + road.heatAt(xw / month) * _Phone.walkRise) * g;

  /// The caravan leader's place across the stage.
  double get leader => StageFrame.side + _Phone.left + (60 + 272) * puppet;

  /// The road's offset at the camera month [t]: the road pixel at the stage's start edge.
  double cameraX(double t) => t * month - size.width / 2;

  /// The camera month that stands the stop at [at] where a chosen stop stands.
  double cameraFor(double at) => at - (focus - 0.5) * size.width / month;

  /// The month under the caravan leader at the camera month [t].
  double leaderMonth(double t) => (cameraX(t) + leader) / month;

  /// How many months the stage shows.
  double get span => size.width / month;

  /// Where the post of the year starting at month [at] stands, in road pixels: just before the year, and the first
  /// year's a little before the road, clear of the first stop.
  double postAt(int n, int at) => (n == 0 ? -0.3 : at - 0.05) * month;
}

/// The stage's parts that never move against the road, drawn once per size: the far hills and their landmarks, and
/// the road with its land, its two ways and its posts.
final class StageArt {
  StageArt(this.geometry, {required this.mirrored}) {
    far = _record(_drawFar);
    near = _record(_drawNear);
  }

  final StageGeometry geometry;

  /// Whether the stage is drawn for a right-to-left language; the years on the posts are written the right way round.
  final bool mirrored;

  /// The far layer, which moves at [farRate] of the road's pace.
  late final ui.Picture far;

  /// The road layer.
  late final ui.Picture near;

  static const farRate = 0.45;
  static const _pad = 900.0;

  ui.Picture _record(void Function(Canvas) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording();
  }

  void dispose() {
    far.dispose();
    near.dispose();
  }

  void _drawFar(Canvas canvas) {
    final geo = geometry;
    final h = geo.size.height;
    final w = geo.road.length * geo.month * farRate;
    final half = geo.size.width / 2;
    // The hills: a seeded ridge, the same on every draw.
    var seed = 21;
    double rnd() => (seed = (seed * 16807) % 2147483647) / 2147483647;
    const rough = _Phone.ridge;
    final ridgeBase = geo.base - geo.amp * 0.85;
    final ridgeAmp = geo.amp * 0.5;
    final ridge = <Offset>[
      for (var x = -_pad; x <= w + _pad; x += rough) Offset(x, ridgeBase - ridgeAmp * (0.35 + 0.65 * rnd())),
    ];
    final hill = Path()
      ..moveTo(-_pad, h)
      ..lineTo(ridge.first.dx, ridge.first.dy);
    for (var i = 1; i < ridge.length; i++) {
      final a = ridge[i - 1];
      final b = ridge[i];
      hill.quadraticBezierTo(a.dx + rough / 2, math.min(a.dy, b.dy) - ridgeAmp * 0.1, b.dx, b.dy);
    }
    hill
      ..lineTo(w + _pad, h)
      ..close();
    canvas
      ..drawPath(hill, Paint()..color = TheatreColors.hill)
      ..drawPath(
        hill,
        Paint()
          ..color = TheatreColors.hillEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    // One landmark a year, faint, so the road passes a place each year.
    final years = geo.road.yearStarts;
    canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.35));
    for (var n = 0; n < years.length; n++) {
      final month = n == 0 ? 0.2 : years[n].at.toDouble();
      final x = (month * geo.month - half) * farRate + half;
      canvas
        ..save()
        ..translate(x, geo.base - geo.amp * 0.9)
        ..scale(_Phone.landmark * geo.g);
      landmarkOf(n).paint(canvas);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawNear(Canvas canvas) {
    final geo = geometry;
    final h = geo.size.height;
    final w = geo.road.length * geo.month;
    final band = _Phone.band * geo.g;
    final hide = TheatreColors.hide;

    final land = Path()..moveTo(-_pad, geo.ground(-_pad));
    for (var x = -_pad; x <= w + _pad; x += 8) {
      land.lineTo(x, geo.ground(x));
    }
    for (var x = w + _pad; x >= -_pad; x -= 8) {
      land.lineTo(x, geo.ground(x) + band);
    }
    land.close();
    final lowLand = Path()..moveTo(-_pad, geo.walk(-_pad));
    for (var x = -_pad; x <= w + _pad; x += 10) {
      lowLand.lineTo(x, geo.walk(x) - (4 + 6 * math.sin(x / 90)) * geo.g);
    }
    lowLand
      ..lineTo(w + _pad, h)
      ..lineTo(-_pad, h)
      ..close();
    final landFill = Paint()..color = TheatreColors.land;
    final landEdge = Paint()
      ..color = hide
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas
      ..drawPath(land, landFill)
      ..drawPath(land, landEdge)
      ..drawPath(lowLand, landFill)
      ..drawPath(lowLand, landEdge);

    // The two ways: dashes of the hide along each level.
    void dashes(double Function(double) y, double width, double gap, double alpha) {
      final paint = Paint()
        ..color = hide.withValues(alpha: alpha)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      for (var x = -_pad; x <= w + _pad; x += gap) {
        canvas.drawLine(Offset(x, y(x)), Offset(x + 2, y(x + 2)), paint);
      }
    }

    dashes((x) => geo.walk(x) + 6 * geo.g, 4, 12, 0.5);
    dashes((x) => geo.ground(x) + 7, 5, 11, 0.35);

    // A post at each year's start, with the year on its medallion.
    final years = geo.road.yearStarts;
    for (var n = 0; n < years.length; n++) {
      final x = geo.postAt(n, years[n].at);
      canvas
        ..save()
        ..translate(x, geo.ground(x) + 2)
        ..scale(geo.post);
      postPiece.paint(canvas);
      final text = TextPainter(
        text: TextSpan(
          text: '${years[n].year}',
          style: TextStyle(color: hide, fontSize: 15, fontWeight: FontWeight.w700, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.translate(postYearCentre.dx, postYearCentre.dy);
      if (mirrored) canvas.scale(-1, 1);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2 + 1));
      text.dispose();
      canvas.restore();
    }
  }
}

/// A stop's name over its prop: laid out once, drawn each frame where the prop stands.
final class StopLabel {
  /// [style] is the app's label face, which the name is set in, in the cloth's colour.
  StopLabel(String title, {required double maxWidth, required TextDirection textDirection, TextStyle? style})
    : painter = TextPainter(
        text: TextSpan(
          text: title,
          style: (style ?? const TextStyle()).copyWith(
            color: TheatreColors.clothA,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: textDirection,
      )..layout(maxWidth: maxWidth);

  final TextPainter painter;

  Size get size => Size(painter.width + 16, painter.height + 7);

  void dispose() => painter.dispose();
}

/// Paints the shadow play at the [journey]'s month: the theatre, the far hills, the road and its stops, the caravan
/// walking at the start edge, and the chosen stop lit with its name over it.
class ShadowStagePainter extends CustomPainter {
  ShadowStagePainter({
    required this.art,
    required this.journey,
    required this.clock,
    required this.selected,
    required this.labels,
    required this.mirrored,
    required this.reduced,
  }) : super(repaint: Listenable.merge([journey, clock]));

  final StageArt art;
  final CaravanJourney journey;

  /// The seconds the puppets have been moving, for their gait and their wobble.
  final ValueNotifier<double> clock;

  /// The chosen stop.
  final int selected;
  final List<StopLabel> labels;
  final bool mirrored;
  final bool reduced;

  StageGeometry get _geo => art.geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _geo;
    final rect = Offset.zero & size;
    final cloth = Rect.fromLTRB(
      StageFrame.side,
      StageFrame.valance - 4,
      size.width - StageFrame.side,
      size.height - geo.ledge,
    );
    final camX = geo.cameraX(journey.t);

    canvas
      ..save()
      ..clipRect(rect);
    canvas.drawRect(rect, Paint()..color = TheatreColors.frame);
    _paintCloth(canvas, cloth);

    canvas.save();
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    // The art is clipped to the cloth at the top and the sides; the land runs on to the ledge.
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(cloth.left + 4, cloth.top + 4, cloth.right - 4, size.height))
      ..save()
      ..translate(-camX * StageArt.farRate, 0)
      ..drawPicture(art.far)
      ..restore()
      ..save()
      ..translate(-camX, 0)
      ..drawPicture(art.near)
      ..restore();
    final shown = _paintProps(canvas, camX);
    canvas.restore();

    _paintLamp(canvas, cloth);
    _paintValance(canvas, size);
    _paintLedge(canvas, size, geo.ledge);
    _paintCaravan(canvas, camX);
    canvas.restore();

    _paintLabels(canvas, size, shown);
    canvas.restore();
  }

  void _paintCloth(Canvas canvas, Rect cloth) {
    canvas
      ..drawRect(cloth.inflate(5), Paint()..color = TheatreColors.wood)
      ..drawRect(cloth.inflate(2), Paint()..color = TheatreColors.gilt)
      ..drawRect(
        cloth,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cloth.center.dx, cloth.top + cloth.height * 0.58),
            cloth.width * 0.62,
            const [TheatreColors.clothA, TheatreColors.clothB, TheatreColors.clothC],
            const [0, 0.55, 1],
          ),
      );
    // The weave of the cloth.
    final weave = Paint()
      ..color = TheatreColors.weave
      ..strokeWidth = 2;
    for (var x = cloth.left + 1; x < cloth.right; x += 5) {
      canvas.drawLine(Offset(x, cloth.top), Offset(x, cloth.bottom), weave);
    }
  }

  /// Draws the props in view, the chosen one lit and the others dimmed; returns each one's place on the stage, its
  /// top's height and whether it is the chosen one, for the names.
  List<({int index, double x, double top})> _paintProps(Canvas canvas, double camX) {
    final geo = _geo;
    final shown = <({int index, double x, double top})>[];
    final reach = 130 * geo.prop;
    for (final stop in geo.road.stops) {
      final xw = stop.at * geo.month;
      final x = xw - camX;
      if (x < -reach || x > geo.size.width + reach) continue;
      final piece = propOf(stop.index, stop.trend.peak);
      final y = geo.ground(xw) + 1;
      final lit = stop.index == selected;
      shown.add((index: stop.index, x: x, top: y + piece.top * geo.prop * (lit ? 1.07 : 1)));
      canvas
        ..save()
        ..translate(x, y);
      if (lit) {
        // The lamp behind the lit stop: a warm glow, then the prop a little larger.
        final r = -piece.top * geo.prop * 0.85;
        final centre = Offset(0, piece.top * geo.prop * 0.45);
        canvas.drawCircle(
          centre,
          r,
          Paint()..shader = ui.Gradient.radial(centre, r, const [Color(0x99ffd68c), Color(0x00ffd68c)]),
        );
        canvas.scale(geo.prop * 1.07);
        piece.paint(canvas);
      } else {
        canvas
          ..scale(geo.prop)
          ..saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.42));
        piece.paint(canvas);
        canvas.restore();
      }
      canvas.restore();
    }
    return shown;
  }

  void _paintLamp(Canvas canvas, Rect cloth) {
    canvas.drawRect(
      cloth,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cloth.center.dx, cloth.top + cloth.height * 0.55),
          cloth.width * 0.7,
          const [Color(0x00000000), Color(0x00000000), TheatreColors.lamp],
          const [0, 0.4, 1],
        ),
    );
  }

  void _paintValance(Canvas canvas, Size size) {
    final deep = Paint()..color = TheatreColors.valanceDeep;
    final cloth = Paint()..color = TheatreColors.valance;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 10), deep);
    const r = 15.0;
    for (var x = r; x < size.width + r; x += r * 2) {
      canvas.drawCircle(Offset(x, -4), r + 3, cloth);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 4),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 4), const [
          TheatreColors.valanceDeep,
          TheatreColors.valance,
        ]),
    );
  }

  void _paintLedge(Canvas canvas, Size size, double ledge) {
    final top = size.height - ledge;
    canvas
      ..drawRect(Rect.fromLTRB(0, top, size.width, size.height), Paint()..color = TheatreColors.wood)
      ..drawRect(Rect.fromLTRB(0, top, size.width, top + 3), Paint()..color = TheatreColors.gilt)
      ..drawRect(
        Rect.fromLTRB(0, size.height - 6, size.width, size.height - 5),
        Paint()..color = TheatreColors.gilt.withValues(alpha: 0.7),
      );
  }

  void _paintCaravan(Canvas canvas, double camX) {
    final geo = _geo;
    final s = geo.puppet;
    final v = journey.velocity;
    final walking = !reduced && v.abs() > 0.03;
    final back = v < -0.03;
    final seconds = reduced ? 0.0 : clock.value;

    // The camels carry the trends on the road where the caravan is, up to three each.
    final load = geo.road.onRoad((camX + geo.leader) / geo.month);
    final per = math.max(1, (load.length / 2).ceil());
    final camels = [
      for (var n = 0; n < 2; n++)
        Puppets.camel([for (final stop in load.skip(n * per).take(math.min(per, 3))) packOf(stop.index)], n),
    ];
    final cast = <(ArtPiece, double, Rod, double)>[
      (camels[1], -272 * s, Puppets.camelRod, -0.17),
      (camels[0], -150 * s, Puppets.camelRod, 0),
      (Puppets.driver, -72 * s, Puppets.driverRod, -0.3),
      (Puppets.leader, 0, Puppets.leaderRod, 0),
    ];
    final rodEdge = Paint()
      ..color = TheatreColors.hide
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final rodCore = Paint()
      ..color = TheatreColors.rod
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final pin = Paint()..color = ArtColors.goldL;

    for (final (piece, offset, rod, delay) in cast) {
      final sx = geo.leader + offset;
      final xw = camX + sx;
      final gy = geo.walk(xw) + 4 * geo.g;
      final slope = math.atan2(geo.walk(xw + 18) - geo.walk(xw - 18), 36).clamp(-0.21, 0.21);
      // The puppet rocks on its pin, faster while it walks.
      final wobble = reduced
          ? 0.0
          : 2.2 * math.sin((seconds + delay) * math.pi / (walking ? 0.42 : 1.3)) * math.pi / 180;
      final flip = back ? -1.0 : 1.0;
      canvas
        ..save()
        ..translate(sx, gy)
        ..rotate(slope)
        ..save()
        ..rotate(wobble)
        ..scale(flip * s, s);
      piece.paint(canvas, seconds: seconds, walking: walking);
      canvas.restore();
      // The rod stays in the puppeteer's hand while the puppet rocks: a light core in a dark edge, off the stage.
      final from = Offset(rod.pin.dx * flip * s, rod.pin.dy * s);
      final to = Offset(rod.foot * flip * s, 240 * s);
      canvas
        ..drawLine(from, to, rodEdge)
        ..drawLine(from, to, rodCore)
        ..drawCircle(from, 3.4 * s, pin)
        ..restore();
    }
  }

  void _paintLabels(Canvas canvas, Size size, List<({int index, double x, double top})> shown) {
    // The chosen stop's name first, then its neighbours' where they do not meet it.
    final order = [...shown]..sort((a, b) => (b.index == selected ? 1 : 0) - (a.index == selected ? 1 : 0));
    final placed = <Rect>[];
    for (final stop in order) {
      if (stop.index >= labels.length) continue;
      final label = labels[stop.index];
      final lit = stop.index == selected;
      final box = label.size;
      final x = mirrored ? size.width - stop.x : stop.x;
      final left = (x - box.width / 2).clamp(StageFrame.side + 6, size.width - StageFrame.side - 6 - box.width);
      final top = math.max(StageFrame.valance + 2, stop.top - 8 - box.height);
      final r = Rect.fromLTWH(left, top, box.width, box.height);
      if (placed.any((other) => other.inflate(4).overlaps(r))) continue;
      placed.add(r);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
      canvas.saveLayer(r.inflate(3), Paint()..color = Color.fromRGBO(0, 0, 0, lit ? 1 : 0.6));
      canvas
        ..drawRRect(rr, Paint()..color = TheatreColors.hide)
        ..drawRRect(
          rr,
          Paint()
            ..color = lit ? TheatreColors.lampLit : TheatreColors.gilt
            ..style = PaintingStyle.stroke
            ..strokeWidth = lit ? 1.6 : 1,
        );
      label.painter.paint(canvas, Offset(r.left + 8, r.top + 3.5));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ShadowStagePainter old) =>
      old.art != art ||
      old.selected != selected ||
      old.labels != labels ||
      old.mirrored != mirrored ||
      old.reduced != reduced ||
      old.journey != journey;
}
