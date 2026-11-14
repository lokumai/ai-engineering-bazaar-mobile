import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:path_parsing/path_parsing.dart';

/// The cast and the props of the web's shadow play (web M91, `src/components/caravan/scene/art.ts`, C4 Shadow Play),
/// drawn from the web's own path data, so the app's puppets are the web's puppets.
///
/// Every piece has its feet at (0, 0) and faces right, in the web's units; the stage scales it. A piece is a list of
/// [ArtPart]s, each a group of shapes that moves as one: the legs stride and the body bobs while the caravan walks, and
/// the lantern's glow breathes. Each part is recorded once into a [ui.Picture], so a frame draws a few pictures, not
/// hundreds of paths.
///
/// The leather (web `caravan.css`): every filled shape has a dark hide edge under a slightly translucent dye.

/// The art's colours, the web's `ART`.
abstract final class ArtColors {
  static const camel = Color(0xffcda46c);
  static const camelSh = Color(0xffb48a52);
  static const camelFar = Color(0xff9e7a48);
  static const hoof = Color(0xff5b4630);
  static const skin = [Color(0xffd9a47a), Color(0xff8a5a3c), Color(0xffc98f62), Color(0xfff0cfa6), Color(0xffd49a6a)];
  static const robe = [
    Color(0xff282864),
    Color(0xffa0503c),
    Color(0xff2f8c86),
    Color(0xff7a4a86),
    Color(0xff73501f),
    Color(0xffb8873b),
  ];
  static const cream = Color(0xfff6eedf);
  static const stone = Color(0xffefe6d6);
  static const stoneD = Color(0xffd6c7ac);
  static const brick = Color(0xffc9785f);
  static const wood = Color(0xff9c6c34);
  static const woodD = Color(0xff6b4b2c);
  static const iron = Color(0xff25233f);
  static const teal = Color(0xff2f8c86);
  static const tealL = Color(0xff63b2ab);
  static const gold = Color(0xffc99a4b);
  static const goldL = Color(0xffddb46a);
  static const shadow = Color(0xff2b2947);
  static const red = Color(0xffb3262e);
  static const plum = Color(0xff7a4a86);
  static const plumD = Color(0xff573260);
  static const mountain = Color(0xff8c8aa8);
  static const snow = Color(0xfff7f4ee);
  static const sea = Color(0xff63b2ab);
  static const beard = Color(0xff2a1c18);
  static const shade = Color(0x30000000);
}

/// The theatre's own colours, the web's `palette.ts`: the same in both themes, as a shadow play is watched in the dark.
abstract final class TheatreColors {
  static const frame = Color(0xff2a1a10);
  static const wood = Color(0xff4a2c18);
  static const gilt = Color(0xffb8873b);
  static const clothA = Color(0xfffbecc4);
  static const clothB = Color(0xffefd296);
  static const clothC = Color(0xffc98f4e);
  static const weave = Color(0x0d784614);
  static const lamp = Color(0x61461e00);
  static const valance = Color(0xff8e1f26);
  static const valanceDeep = Color(0xff6d1219);
  static const hide = Color(0xff3b2412);
  static const hill = Color(0x2e7a4a86);
  static const hillEdge = Color(0x4d3b2412);
  static const land = Color(0x8c2f8c86);
  static const lampLit = Color(0xffffd88a);
  static const rod = Color(0xffd9b27a);
}

/// The goods a stop's merchant sells, by colour, cycled by the trend's place on the road (the web's `PACKS`).
const List<Color> _packs = [
  Color(0xffa0503c),
  Color(0xffe6dac6),
  Color(0xffb8873b),
  Color(0xffddb46a),
  Color(0xff7a4a86),
  Color(0xff9e9585),
  Color(0xff2f8c86),
  Color(0xff63b2ab),
  Color(0xffc9c6e4),
  Color(0xff282864),
  Color(0xffc99a4b),
  Color(0xff73501f),
];

/// The colour of the goods of the stop at [index].
Color packOf(int index) => _packs[index % _packs.length];

/// The goods' colour of the stop at [index] as ink on the page: a pale one (the cream, the lilac) darkened, so it
/// still reads on a light card.
Color inkOf(int index) {
  final pack = packOf(index);
  return pack.computeLuminance() > 0.45 ? Color.lerp(pack, const Color(0xff000000), 0.4)! : pack;
}

/// The path of SVG path data [d].
Path svgPath(String d) {
  final path = Path();
  writeSvgPathDataToPath(d, _PathProxy(path));
  return path;
}

final class _PathProxy implements PathProxy {
  _PathProxy(this.path);

  final Path path;

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

/// How a part moves.
enum PartMotion {
  /// Still.
  none,

  /// The near legs of a beast, swinging while it walks.
  strideA,

  /// The far legs, swinging against the near ones.
  strideB,

  /// A walker's front leg.
  stepA,

  /// A walker's back leg.
  stepB,

  /// A body or a person, bobbing while it walks.
  bob,

  /// A lantern's glow, breathing.
  glow,
}

/// One shape: a filled or a stroked path in one colour.
final class ArtShape {
  ArtShape(this.path, Color color, {this.stroke, double opacity = 1, this.leather = true})
    : paint = Paint()
        ..isAntiAlias = true
        ..color = color.withValues(alpha: color.a * opacity * (stroke == null && leather ? 0.88 : 1))
        ..style = stroke == null ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = stroke ?? 0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  final Path path;
  final Paint paint;

  /// The stroke's width, or null for a filled shape.
  final double? stroke;

  /// Whether a filled shape gets the leather's hide edge.
  final bool leather;

  static final Paint _edge = Paint()
    ..isAntiAlias = true
    ..color = TheatreColors.hide
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeJoin = StrokeJoin.round;

  void paintOn(Canvas canvas) {
    // The edge first and the dye over it, as the web's `paint-order: stroke`.
    if (stroke == null && leather) canvas.drawPath(path, _edge);
    canvas.drawPath(path, paint);
  }
}

/// A group of shapes that moves as one, about [pivot] (the top of its middle, as the web's `transform-origin: 50% 0`).
final class ArtPart {
  ArtPart(this.shapes, {this.motion = PartMotion.none, this.delay = 0}) : pivot = _topMiddle(shapes);

  static Offset _topMiddle(List<ArtShape> shapes) {
    if (shapes.isEmpty) return Offset.zero;
    final bounds = shapes.map((shape) => shape.path.getBounds()).reduce((a, b) => a.expandToInclude(b));
    return Offset(bounds.center.dx, bounds.top);
  }

  final List<ArtShape> shapes;
  final PartMotion motion;
  final Offset pivot;

  /// The part's phase offset, in seconds.
  final double delay;

  ui.Picture? _picture;

  /// The part drawn once.
  ui.Picture get picture => _picture ??= () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final shape in shapes) {
      shape.paintOn(canvas);
    }
    return recorder.endRecording();
  }();
}

/// A puppet or a prop: its parts, drawn in order.
final class ArtPiece {
  ArtPiece(this.parts, {this.top = 0});

  final List<ArtPart> parts;

  /// The height of its highest point above its feet, negative up (a prop's flag top).
  final double top;

  /// Draws the piece at the canvas origin, its parts moved for [seconds] of the clock while [walking].
  void paint(Canvas canvas, {double seconds = 0, bool walking = false}) {
    for (final part in parts) {
      final moving = part.motion != PartMotion.none && (walking || part.motion == PartMotion.glow);
      if (!moving) {
        canvas.drawPicture(part.picture);
        continue;
      }
      final time = seconds + part.delay;
      switch (part.motion) {
        case PartMotion.glow:
          // From full to half, 1.8 s each way.
          final alpha = 0.75 + 0.25 * math.cos(time * math.pi / 1.8);
          canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
          canvas.drawPicture(part.picture);
          canvas.restore();
        case PartMotion.bob:
          canvas
            ..save()
            ..translate(0, -1.4 * _wave(time, 0.31))
            ..drawPicture(part.picture)
            ..restore();
        case PartMotion.strideA || PartMotion.strideB || PartMotion.stepA || PartMotion.stepB:
          final (degrees, period, sign) = switch (part.motion) {
            PartMotion.strideA => (13.0, 0.62, 1.0),
            PartMotion.strideB => (13.0, 0.62, -1.0),
            PartMotion.stepA => (22.0, 0.42, 1.0),
            _ => (22.0, 0.42, -1.0),
          };
          final angle = sign * degrees * (2 * _wave(time, period) - 1) * math.pi / 180;
          canvas
            ..save()
            ..translate(part.pivot.dx, part.pivot.dy)
            ..rotate(angle)
            ..translate(-part.pivot.dx, -part.pivot.dy)
            ..drawPicture(part.picture)
            ..restore();
        case PartMotion.none:
          canvas.drawPicture(part.picture);
      }
    }
  }
}

/// A smooth back and forth between 0 and 1, [period] seconds each way, as CSS's `ease-in-out infinite alternate`.
double _wave(double seconds, double period) => 0.5 - 0.5 * math.cos(seconds * math.pi / period);

/// Collects shapes under one transform: translate by ([dx], [dy]), then scale by ([sx], [sy]).
final class _Pen {
  _Pen({this.dx = 0, this.dy = 0, this.sx = 1, this.sy = 1});

  final double dx;
  final double dy;
  final double sx;
  final double sy;
  final List<ArtShape> shapes = [];

  Path _t(Path path) {
    if (dx == 0 && dy == 0 && sx == 1 && sy == 1) return path;
    final m = Float64List(16)
      ..[0] = sx
      ..[5] = sy
      ..[10] = 1
      ..[12] = dx
      ..[13] = dy
      ..[15] = 1;
    return path.transform(m);
  }

  void fill(String d, Color color, {double opacity = 1}) =>
      shapes.add(ArtShape(_t(svgPath(d)), color, opacity: opacity));

  void stroke(String d, Color color, double width, {double opacity = 1}) =>
      shapes.add(ArtShape(_t(svgPath(d)), color, stroke: width * sx.abs(), opacity: opacity));

  void circle(double cx, double cy, double r, Color color, {double opacity = 1}) => shapes.add(
    ArtShape(
      _t(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))),
      color,
      opacity: opacity,
    ),
  );

  void ellipse(double cx, double cy, double rx, double ry, Color color, {double opacity = 1}) => shapes.add(
    ArtShape(
      _t(Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2))),
      color,
      opacity: opacity,
    ),
  );

  void rect(double x, double y, double w, double h, Color color, {double rx = 0, double opacity = 1}) => shapes.add(
    ArtShape(_t(Path()..addRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(rx)))), color, opacity: opacity),
  );

  /// A dashed line from ([x0], [y]) to ([x1], [y]): [on] drawn, [off] left, as `stroke-dasharray`.
  void dash(double x0, double x1, double y, Color color, double width, {double on = 2, double off = 3}) {
    final d = StringBuffer();
    for (var x = x0; x < x1; x += on + off) {
      d.write('M$x ${y}H${math.min(x + on, x1)}');
    }
    stroke(d.toString(), color, width);
  }

  ArtPart part({PartMotion motion = PartMotion.none, double delay = 0}) =>
      ArtPart(List.of(shapes), motion: motion, delay: delay);
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

// ---- the people and the beasts --------------------------------------------------------------------------------

/// A camel, side on; [pack] is the colour of its first load, or null for none.
List<ArtPart> _camel(Color? pack, {Color blanket = ArtColors.brick, double delay = 0}) {
  ArtPart legs(List<(double, Color)> legs, PartMotion motion) {
    final pen = _Pen(dx: -60, dy: -100);
    for (final (x, color) in legs) {
      pen
        ..stroke('M$x 56 Q${x - 3} 77 $x 97', color, 5.4)
        ..ellipse(x + 1.5, 98, 3.6, 2, ArtColors.hoof);
    }
    return pen.part(motion: motion, delay: delay);
  }

  final body = _Pen(dx: -60, dy: -100)
    ..stroke('M18 47C12 52 12 60 14 66', ArtColors.camelSh, 2.6)
    ..fill(
      'M18 52C16 40 26 32 38 33C44 18 62 14 72 30C78 32 84 36 88 42C92 34 94 22 98 14C100 9 108 8 112 11L116.5 '
      '16.5C113 18.5 109 18.5 107 19.5C104 28 100 40 96 50C93 58 88 62 80 62L32 62C24 62 19 58 18 52Z',
      ArtColors.camel,
    )
    ..fill('M32 62L80 62C76 55 40 55 32 62Z', ArtColors.camelSh)
    ..fill('M104 10l-2-5 4 3Z', ArtColors.camelSh)
    ..circle(109, 13, 1.3, ArtColors.iron);
  final load = _Pen(dx: -60, dy: -100)
    ..fill('M34 47C40 25 64 22 72 40L72 47Z', blanket)
    ..dash(34, 72, 47, ArtColors.goldL, 2.4);
  if (pack != null) {
    load
      ..rect(39, 40, 28, 23, pack, rx: 4)
      ..stroke('M39 47h28M39 55h28', const Color(0x26000000), 2)
      ..stroke('M53 40v23', const Color(0x20000000), 1.5);
  }
  load.stroke('M96 30 C92 38 70 50 72 54', ArtColors.woodD, 1.2, opacity: 0.7);
  return [
    legs([(39, ArtColors.camelFar), (81, ArtColors.camelFar)], PartMotion.strideB),
    body.part(motion: PartMotion.bob, delay: delay),
    legs([(31, ArtColors.camel), (89, ArtColors.camel)], PartMotion.strideA),
    load.part(motion: PartMotion.bob, delay: delay),
  ];
}

/// The caravan bashi's horse.
List<ArtPart> _horse(Color body, Color dark, Color saddle) {
  ArtPart legs(List<(double, Color)> legs, PartMotion motion) {
    final pen = _Pen(dx: -42, dy: -72);
    for (final (x, color) in legs) {
      pen.stroke('M$x 40 L${x - 1} 58 L$x 70', color, 4.6);
    }
    return pen.part(motion: motion);
  }

  final pen = _Pen(dx: -42, dy: -72)
    ..stroke('M10 30 C6 36 6 46 9 52', dark, 4)
    ..fill(
      'M12 30 C12 20 22 18 34 19 L56 19 C62 12 66 4 72 2 C78 0 84 4 86 9 L84 13 C80 12 77 13 75 15 C72 22 68 30 66 '
      '36 C64 42 58 44 50 44 L22 44 C15 44 12 38 12 30Z',
      body,
    )
    ..fill('M58 18 C62 8 68 2 74 1 L70 10 C66 14 62 20 60 22Z', dark)
    ..circle(79, 6, 1.2, ArtColors.iron);
  final tack = _Pen(dx: -42, dy: -72)
    ..fill('M28 18 C30 10 46 10 48 18 L48 26 L28 26Z', saddle)
    ..stroke('M28 26h20', ArtColors.goldL, 2);
  return [
    legs([(20, dark), (60, dark)], PartMotion.strideB),
    pen.part(motion: PartMotion.bob),
    legs([(26, body), (66, body)], PartMotion.strideA),
    tack.part(motion: PartMotion.bob),
  ];
}

enum _Hat { turban, fez, cap }

enum _Prop { none, lantern, banner }

/// A person in period dress, side on (the web's `personSVG`), drawn under the transform of [dx], [dy], [sx], [sy].
List<ArtPart> _person({
  Color skin = const Color(0xffd9a47a),
  Color robe = const Color(0xff282864),
  Color sash = ArtColors.goldL,
  Color turban = ArtColors.cream,
  Color? beard,
  _Hat hat = _Hat.turban,
  _Prop prop = _Prop.none,
  Color flag = ArtColors.teal,
  bool legs = true,
  double dx = 0,
  double dy = 0,
  double sx = 1,
  double sy = 1,
  PartMotion bob = PartMotion.bob,
}) {
  _Pen pen() => _Pen(dx: dx, dy: dy, sx: sx, sy: sy);
  final parts = <ArtPart>[];
  if (legs) {
    parts
      ..add((pen()..stroke('M-3 -16 L-5 -1', ArtColors.woodD, 4)).part(motion: PartMotion.stepA))
      ..add((pen()..stroke('M3 -16 L5 -1', ArtColors.woodD, 4)).part(motion: PartMotion.stepB))
      ..add(
        (pen()
              ..ellipse(-4, -1, 4, 2, ArtColors.iron)
              ..ellipse(6, -1, 4, 2, ArtColors.iron))
            .part(),
      );
  }
  final body = pen()
    ..fill('M-8 -58C-12 -40 -14 -24 -15 -12L15 -12C13 -26 11 -42 8 -58Z', robe)
    ..fill('M-15 -12L15 -12L14.4 -16L-14.4 -16Z', ArtColors.shade)
    ..rect(-10.6, -40, 21.2, 5, sash, rx: 1.5)
    ..fill('M-2 -60 L4 -60 L3 -55 L-1 -55Z', skin)
    ..circle(1, -66, 7.6, skin)
    ..circle(8, -65.5, 2, skin)
    ..circle(5, -68, 1.1, ArtColors.iron);
  if (beard != null) body.fill('M-1 -62 C0 -54 7 -55 8 -61Z', beard);
  switch (hat) {
    case _Hat.fez:
      body
        ..fill('M-6 -71 L-5 -80 L6 -80 L7 -71Z', const Color(0xffa0503c))
        ..stroke('M5 -80 q5 3 4 9', ArtColors.iron, 1.2);
    case _Hat.cap:
      body
        ..fill('M-8 -70 C-8 -79 8 -79 8 -70Z', ArtColors.tealL)
        ..rect(-9, -71.5, 18, 3, ArtColors.gold, rx: 1.5);
    case _Hat.turban:
      body
        ..ellipse(0, -72, 9.4, 6.2, turban)
        ..stroke('M-6 -75 q6 -4 12 0', const Color(0x18000000), 2)
        ..stroke('M-8 -70 q-4 6 -2 12', turban, 3);
  }
  ArtPart? glow;
  switch (prop) {
    case _Prop.lantern:
      body
        ..stroke('M10 -36 L13 -92', ArtColors.woodD, 2.4)
        ..stroke('M13 -92 q9 0 9 8', ArtColors.iron, 1.3);
      glow = (pen()..circle(22, -77, 9, ArtColors.goldL, opacity: 0.28)).part(motion: PartMotion.glow);
    case _Prop.banner:
      body
        ..stroke('M10 -36 L12 -100', ArtColors.woodD, 2.4)
        ..fill('M12 -100 C22 -102 28 -96 36 -98 L34 -86 C26 -84 20 -90 12 -88Z', flag);
    case _Prop.none:
  }
  final lamp = pen();
  if (prop == _Prop.lantern) {
    lamp
      ..rect(18.5, -84, 7, 10, ArtColors.goldL, rx: 2)
      ..stroke('M18 -84h8M18 -74h8', ArtColors.iron, 1.6);
  }
  final arm = pen()
    ..stroke('M1 -55 L10 -37', robe, 5.4)
    ..stroke('M1 -55 L10 -37', ArtColors.shade, 5.4, opacity: 0.5)
    ..circle(10.5, -36, 2.6, skin);
  parts.add(body.part(motion: bob));
  if (glow != null) parts.add(glow);
  parts
    ..add(lamp.part(motion: bob))
    ..add(arm.part(motion: bob));
  return parts;
}

/// The tallest puppet's height above its feet, in the art's units: the tip of the leader's banner.
const double puppetHeight = 144;

/// The tallest prop's height above the land, in the art's units: the serai's flags.
const double propHeight = 150;

/// A puppet's rod: where it is pinned to the leather and where it leaves the stage, in the puppet's units.
typedef Rod = ({Offset pin, double foot});

/// The caravan's four puppets, each on its rod.
abstract final class Puppets {
  /// The leader on horseback, with the banner.
  static final ArtPiece leader = ArtPiece([
    ..._horse(ArtColors.plum, ArtColors.plumD, ArtColors.red),
    ..._person(
      robe: ArtColors.teal,
      turban: ArtColors.cream,
      beard: ArtColors.beard,
      prop: _Prop.banner,
      flag: ArtColors.red,
      legs: false,
      dx: 4,
      dy: -46,
      sx: 0.95,
      sy: 0.95,
    ),
  ]);

  static const Rod leaderRod = (pin: Offset(0, -40), foot: 22);

  /// The driver on foot, with the lantern.
  static final ArtPiece driver = ArtPiece(
    _person(
      robe: const Color(0xffb8873b),
      skin: ArtColors.skin[1],
      hat: _Hat.fez,
      prop: _Prop.lantern,
      sash: ArtColors.red,
      beard: ArtColors.beard,
    ),
  );

  static const Rod driverRod = (pin: Offset(0, -40), foot: 12);

  static const Rod camelRod = (pin: Offset(-4, -48), foot: 16);

  static final Map<String, ArtPiece> _camels = {};

  /// A camel carrying up to three [loads], one per trend on the road there, in their colours; [k] is its place in
  /// the line, which shifts its gait.
  static ArtPiece camel(List<Color> loads, int k) {
    final key = '$k:${loads.map((c) => c.toARGB32()).join(',')}';
    return _camels[key] ??= () {
      final delay = k * -0.17;
      final extra = _Pen(dx: -60, dy: -100);
      if (loads.length > 1) {
        extra
          ..rect(43, 8, 22, 15, loads[1], rx: 4)
          ..stroke('M43 15h22', const Color(0x26000000), 2);
      }
      if (loads.length > 2) extra.ellipse(33, 40, 7, 9, loads[2]);
      return ArtPiece([
        ..._camel(loads.isEmpty ? null : loads.first, blanket: ArtColors.red, delay: delay),
        extra.part(motion: PartMotion.bob, delay: delay),
      ]);
    }();
  }
}

// ---- a stop's prop, by how strong the trend was -----------------------------------------------------------------

/// The kind of prop a trend's stop stands as: a serai for a level-5 trend, a tent for 4, a stall for 3, a stone below.
enum PropKind { serai, tent, stall, stone }

PropKind propKindOf(int peak) => switch (peak) {
  >= 5 => PropKind.serai,
  4 => PropKind.tent,
  3 => PropKind.stall,
  _ => PropKind.stone,
};

final Map<int, ArtPiece> _props = {};

/// The prop of the stop at [index] for a trend of [peak]: the web's `stopArt`.
ArtPiece propOf(int index, int peak) => _props[index * 10 + peak] ??= _buildProp(index, peak);

ArtPiece _buildProp(int i, int peak) {
  final pack = packOf(i);
  final kind = propKindOf(peak);
  List<ArtPart> merchant(double dx) => _person(
    robe: ArtColors.robe[i % 6],
    skin: ArtColors.skin[i % 5],
    turban: i % 3 != 0 ? ArtColors.cream : ArtColors.goldL,
    hat: i % 4 == 1 ? _Hat.fez : (i % 4 == 3 ? _Hat.cap : _Hat.turban),
    beard: i.isOdd ? ArtColors.beard : null,
    dx: dx,
    sx: -0.9,
    sy: 0.9,
    bob: PartMotion.none,
  ).map((part) => ArtPart(part.shapes)).toList();
  void goods(_Pen pen, double dx) {
    final p = _Pen(dx: dx);
    p
      ..fill('M-14 0 C-15 -12 -6 -16 -1 -15 C4 -16 12 -12 11 0Z', pack)
      ..fill('M2 0 C1 -9 8 -12 12 -11 C17 -11 21 -7 20 0Z', _mix(pack, const Color(0xff000000), 0.18))
      ..stroke('M-6 -15 l3 -4 3 4', ArtColors.woodD, 1.4);
    pen.shapes.addAll(p.shapes);
  }

  final pen = _Pen();
  final List<ArtPart> people;
  final double top;
  switch (kind) {
    case PropKind.serai:
      top = -150;
      pen
        ..rect(-92, -92, 184, 92, ArtColors.stone)
        ..stroke('M-92 -92h184', ArtColors.stoneD, 4);
      for (final v in [-80.0, -56, -32, 32, 56, 80]) {
        pen.rect(v - 6, -100, 12, 9, ArtColors.stone);
      }
      pen
        ..circle(0, -96, 34, ArtColors.tealL)
        ..fill('M-34 -96 A34 34 0 0 1 34 -96Z', ArtColors.teal, opacity: 0.35)
        ..stroke('M0 -130 v-14', ArtColors.gold, 3)
        ..circle(0, -146, 4, ArtColors.goldL)
        ..rect(-104, -122, 26, 122, ArtColors.stone)
        ..rect(78, -122, 26, 122, ArtColors.stone)
        ..fill('M-104 -122 a13 13 0 0 1 26 0Z M78 -122 a13 13 0 0 1 26 0Z', ArtColors.brick)
        ..fill('M-30 0 V-46 A30 30 0 0 1 30 -46 V0Z', ArtColors.brick)
        ..fill('M-23 0 V-44 A23 23 0 0 1 23 -44 V0Z', ArtColors.shadow)
        ..fill('M-16 0 V-36 A16 16 0 0 1 16 -36 V0Z', const Color(0xff3a3456))
        ..circle(0, -30, 5, ArtColors.goldL);
      for (final v in [-62.0, -46, 46, 62]) {
        pen.fill('M${v - 5} -54 V-66 a5 5 0 0 1 10 0 V-54Z', ArtColors.shadow);
      }
      pen
        ..stroke('M-91 -122 V-146', ArtColors.woodD, 2)
        ..fill('M-91 -146 C-80 -148 -74 -142 -66 -144 L-68 -132 C-76 -130 -82 -136 -91 -134Z', pack)
        ..stroke('M91 -122 V-146', ArtColors.woodD, 2)
        ..fill('M91 -146 C102 -148 108 -142 116 -144 L114 -132 C106 -130 100 -136 91 -134Z', pack);
      goods(pen, -64);
      people = merchant(52);
    case PropKind.tent:
      top = -112;
      pen.fill('M-62 0 L-50 -56 Q0 -104 50 -56 L62 0Z', pack);
      for (final v in [-36.0, 12]) {
        pen.fill(
          'M${v * 0.82} -70 L${v * 1.15} 0 L${v * 1.15 + 10} 0 L${v * 0.82 + 8} -72Z',
          ArtColors.cream,
          opacity: 0.55,
        );
      }
      pen
        ..stroke('M-50 -56 Q0 -40 50 -56', _mix(pack, const Color(0xff000000), 0.25), 3)
        ..fill('M-14 0 L0 -44 L14 0Z', ArtColors.shadow)
        ..fill('M0 -44 L-20 0 L-12 0Z', _mix(pack, const Color(0xff000000), 0.2))
        ..stroke('M0 -84 V-104', ArtColors.woodD, 2.4)
        ..fill('M0 -104 C10 -106 16 -100 24 -102 L22 -90 C14 -88 8 -94 0 -92Z', ArtColors.goldL);
      goods(pen, -74);
      people = merchant(64);
    case PropKind.stall:
      top = -92;
      pen
        ..stroke('M-40 -64 V0 M40 -64 V0', ArtColors.wood, 5)
        ..rect(-44, -34, 88, 34, ArtColors.wood, rx: 3)
        ..stroke('M-44 -24h88', ArtColors.woodD, 2)
        ..fill('M-52 -64 L52 -64 L46 -80 L-46 -80Z', ArtColors.cream);
      for (final v in [-46.0, -24, -2, 20]) {
        pen.fill('M$v -80 L${v + 11} -80 L${v + 12} -64 L$v -64Z', pack);
      }
      pen.fill('M-52 -64 q8 8 16 0 q8 8 16 0 q8 8 16 0 q8 8 16 0 q8 8 16 0 q8 8 16 0 q8 8 8 0', pack);
      var k = 0;
      for (final v in [-30.0, -14, 2, 18]) {
        pen.circle(v + 4, -40, 7, k.isOdd ? pack : _mix(pack, const Color(0xffffffff), 0.25));
        k++;
      }
      people = merchant(56);
    case PropKind.stone:
      top = -70;
      pen
        ..fill('M-12 0 V-40 A12 12 0 0 1 12 -40 V0Z', ArtColors.stoneD)
        ..stroke('M-6 -36h12M-6 -28h12M-6 -20h8', ArtColors.woodD, 1.6, opacity: 0.6)
        ..stroke('M18 0 V-64', ArtColors.woodD, 2)
        ..fill('M18 -64 C28 -66 34 -60 42 -62 L40 -50 C32 -48 26 -54 18 -52Z', pack);
      people = const [];
  }
  return ArtPiece([pen.part(), ...people], top: top);
}

// ---- the places the road passes, one a year ---------------------------------------------------------------------

void _palm(_Pen pen, double x, double y, double s) {
  final p = _Pen(dx: x, dy: y, sx: s, sy: s)..stroke('M0 0 C2 -20 -2 -40 6 -62', ArtColors.wood, 5);
  for (final (a, b) in const [
    (-30.0, -52.0),
    (-24.0, -72.0),
    (8.0, -84.0),
    (32.0, -70.0),
    (36.0, -50.0),
    (-8.0, -82.0),
  ]) {
    p.stroke('M6 -62 Q${(6 + a) / 2} ${b - 12} $a $b', ArtColors.teal, 5);
  }
  pen.shapes.addAll(p.shapes);
}

final Map<int, ArtPiece> _landmarks = {};

/// The landmark of the [place]th place the road passes (0 the city gate, 1 the oasis, 2 the caravanserai town, 3 the
/// mountain pass, 4 the sea port), as the web's `landmarkArt`.
ArtPiece landmarkOf(int place) => _landmarks[place % 5] ??= () {
  final pen = _Pen();
  switch (place % 5) {
    case 0:
      pen.rect(-150, -120, 300, 120, ArtColors.stone);
      for (final v in [-140.0, -110, -80, 80, 110, 140]) {
        pen.rect(v - 8, -132, 16, 13, ArtColors.stone);
      }
      pen
        ..rect(-70, -180, 40, 180, ArtColors.stone)
        ..rect(30, -180, 40, 180, ArtColors.stone)
        ..fill('M-70 -180 a20 20 0 0 1 40 0Z M30 -180 a20 20 0 0 1 40 0Z', ArtColors.brick)
        ..fill('M-30 0 V-80 A30 30 0 0 1 30 -80 V0Z', ArtColors.shadow)
        ..stroke('M-30 -80 A30 30 0 0 1 30 -80', ArtColors.brick, 7);
    case 1:
      pen
        ..ellipse(0, -6, 130, 16, ArtColors.tealL)
        ..ellipse(0, -8, 96, 9, const Color(0xff9fd3cc), opacity: 0.7);
      _palm(pen, -110, 0, 1.4);
      _palm(pen, -60, -4, 1.1);
      _palm(pen, 90, 0, 1.5);
      _palm(pen, 140, -2, 1.05);
    case 2:
      for (final (x0, hh, r) in const [
        (-150.0, 70.0, 22.0),
        (-90.0, 110.0, 34.0),
        (-20.0, 90.0, 28.0),
        (50.0, 120.0, 40.0),
        (120.0, 80.0, 24.0),
      ]) {
        pen
          ..rect(x0, -hh, r * 2 + 10, hh, ArtColors.stone)
          ..circle(x0 + r + 5, -hh, r, ArtColors.tealL);
      }
      pen
        ..rect(176, -200, 18, 200, ArtColors.stone)
        ..rect(172, -160, 26, 8, ArtColors.stoneD)
        ..fill('M176 -200 L185 -226 L194 -200Z', ArtColors.teal);
    case 3:
      pen
        ..fill('M-220 0 L-120 -210 L-60 -130 L0 -260 L80 -150 L140 -210 L230 0Z', ArtColors.mountain)
        ..fill(
          'M-120 -210 L-140 -170 L-112 -180 L-96 -164 Z M0 -260 L-28 -206 L2 -220 L26 -200Z M140 -210 L124 -176 L144 '
          '-184 L160 -170Z',
          ArtColors.snow,
        );
    default:
      pen
        ..fill('M-30 -14 C-70 20 -90 80 -120 386 L6000 386 L6000 -14Z', ArtColors.sea)
        ..stroke('M-30 -14 C-70 20 -90 80 -120 386', ArtColors.cream, 6, opacity: 0.7)
        ..stroke(
          'M-60 -10 q20 -6 40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0',
          const Color(0xffffffff),
          2,
          opacity: 0.6,
        );
      final ship = _Pen(dx: 140, dy: -14)
        ..fill('M-60 0 L60 0 L46 22 L-46 22Z', ArtColors.wood)
        ..stroke('M0 0 V-120', ArtColors.woodD, 4)
        ..fill('M4 -116 C40 -90 44 -40 4 -16Z', ArtColors.cream)
        ..fill('M-4 -104 C-36 -80 -38 -40 -4 -20Z', ArtColors.cream, opacity: 0.85)
        ..fill('M0 -120 C10 -122 16 -116 24 -118 L22 -108 C14 -106 8 -112 0 -110Z', ArtColors.brick);
      pen.shapes.addAll(ship.shapes);
      pen
        ..rect(-40, -150, 30, 136, ArtColors.stone)
        ..fill('M-40 -150 L-25 -176 L-10 -150Z', ArtColors.brick)
        ..circle(-25, -158, 6, ArtColors.goldL);
  }
  return ArtPiece([pen.part()]);
}();

/// A year's post: a pole and a medallion; the year is written on it by the stage.
final ArtPiece postPiece = ArtPiece([
  (_Pen()
        ..stroke('M0 0 V-96', TheatreColors.hide, 3)
        ..circle(0, -118, 26, ArtColors.red)
        ..circle(0, -118, 19, ArtColors.goldL)
        ..stroke('M-26 -118 C-40 -132 -40 -150 -26 -156 M26 -118 C40 -132 40 -150 26 -156', ArtColors.teal, 5))
      .part(),
]);

/// Where a post's year is written, in the post's units.
const Offset postYearCentre = Offset(0, -118);
