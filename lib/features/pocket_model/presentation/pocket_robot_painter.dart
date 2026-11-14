import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// The face the robot shows.
enum RobotFace { calm, happy, eating, hungry, asleep, overfit, hallucinating, cold }

/// A short turn the robot plays on top of its face: one of several, so a tap or a feed does not do the same thing
/// every time. Each runs for [RobotTricks.length] seconds.
enum RobotTrick {
  /// Pet: it blushes and wiggles side to side.
  wiggle,

  /// Pet: its fez hops off its head, turns once, and lands.
  fezHop,

  /// Petted three times fast: its fez flies high, spinning, and falls back on, while it gapes.
  fezFly,

  /// Pet: stars for eyes.
  starEyes,

  /// Pet: the tassel's bead swings round and round.
  tasselSpin,

  /// Asked: it thinks before it speaks, dots on its screen, eyes up, the bead blinking.
  thinking,

  /// Speaking hot: its face flickers like a bad signal.
  glitch,

  /// Idle: a yawn.
  yawn,
}

/// How long each trick runs, in seconds.
abstract final class RobotTricks {
  static double length(RobotTrick trick) => switch (trick) {
    RobotTrick.wiggle => 0.9,
    RobotTrick.fezHop => 0.8,
    RobotTrick.fezFly => 1.5,
    RobotTrick.starEyes => 1.4,
    RobotTrick.tasselSpin => 1.2,
    RobotTrick.thinking => 0.7,
    RobotTrick.glitch => 1.6,
    RobotTrick.yawn => 1.5,
  };
}

/// One moment of the pocket model's stage, as the painter draws it.
final class RobotFrame {
  const RobotFrame({
    required this.time,
    required this.face,
    required this.look,
    required this.blink,
    required this.hop,
    required this.temperature,
    required this.level,
    required this.particles,
    required this.alive,
    required this.mirrored,
    this.trick,
    this.trickTime = 0,
  });

  /// The trick it is playing, if any, and how many seconds into it.
  final RobotTrick? trick;
  final double trickTime;

  /// How far into its trick it is, 0 to 1, or null when it plays none.
  double? trickAt(RobotTrick which) {
    if (trick != which) return null;
    final t = trickTime / RobotTricks.length(which);
    return t < 0 || t > 1 ? null : t;
  }

  /// Seconds on the stage's clock.
  final double time;
  final RobotFace face;

  /// Where the eyes look, each axis from -1 to 1.
  final Offset look;

  /// How closed the eyes are, 0 open to 1 shut.
  final double blink;

  /// How high it hops, 0 to 1.
  final double hop;

  /// Its temperature, 0 to 2: the bead on its fez glows from blue through gold to red.
  final double temperature;
  final int level;
  final List<Particle> particles;

  /// Whether it breathes and sways: only for a while after the reader touched it, so the stage rests otherwise.
  final bool alive;
  final bool mirrored;
}

/// What flies on the stage: the tokens it eats, hearts, confetti, sparks, the crumbs it drops, the stars of a new word,
/// its frosty breath when cold, and the bubble of a burp.
enum ParticleKind { token, heart, confetti, spark, crumb, star, frost, burp }

/// One thing flying: born at [born] seconds on the stage's clock, living [life] seconds.
final class Particle {
  const Particle({
    required this.kind,
    required this.born,
    required this.life,
    required this.from,
    required this.to,
    this.label = '',
    this.color = const Color(0xffddb46a),
    this.spin = 0,
    this.swirl = 0,
  });

  final ParticleKind kind;
  final double born;
  final double life;

  /// Where it starts and where it goes, as fractions of the stage.
  final Offset from;
  final Offset to;
  final String label;
  final Color color;
  final double spin;

  /// A token that spirals into the mouth instead of arcing: the whirl's first radius, as a fraction of the stage's width.
  final double swirl;

  /// How far along its life it is at [time], or null when not yet born or gone.
  double? at(double time) {
    final t = (time - born) / life;
    return t < 0 || t > 1 ? null : t;
  }
}

/// The stage's fixed colours: the robot is the same in both themes, as a toy on a shelf is.
abstract final class RobotColors {
  static const body = Color(0xff282864);
  static const bodyLight = Color(0xff3a3a86);
  static const head = Color(0xff1d1f27);
  static const rim = Color(0xff444854);
  static const eye = Color(0xff7fe0d6);
  static const eyeWarm = Color(0xffffd88a);
  static const eyeOdd = Color(0xffe08ad6);
  static const fez = Color(0xffa0503c);
  static const fezDark = Color(0xff7d3a2b);
  static const belly = Color(0xff2f8c86);
  static const cheek = Color(0x66ff8a8a);
  static const rugA = Color(0xff8e1f26);
  static const rugB = Color(0xffc8a078);
  static const rugC = Color(0xff2f8c86);
  static const ink = Color(0xff1b1b47);
}

/// The bead's colour at [temperature]: cold blue, warm gold, hot red.
Color beadColour(double temperature) {
  const cold = Color(0xff7fb8e8);
  const warm = Color(0xffddb46a);
  const hot = Color(0xffe0503c);
  return temperature <= 1
      ? Color.lerp(cold, warm, temperature.clamp(0, 1))!
      : Color.lerp(warm, hot, (temperature - 1).clamp(0, 1))!;
}

/// Paints the pocket model on its rug, its face, the bead of its fez and whatever flies around it.
class PocketRobotPainter extends CustomPainter {
  PocketRobotPainter({required this.frame, required Listenable super.repaint});

  /// Reads the moment to draw; called on every paint.
  final RobotFrame Function() frame;

  /// Where the robot sits in a stage of [size]: the middle of its feet, past the middle toward the end side, so what it
  /// says has the start side.
  static Offset seat(Size size, {bool mirrored = false}) =>
      Offset(size.width * (mirrored ? 0.34 : 0.66), size.height - 30);

  /// The robot's scale in a stage of [size].
  static double scaleOf(Size size) => (size.height / 220).clamp(0.7, 1.3);

  /// Whether [point] is on the robot in a stage of [size].
  static bool hits(Size size, Offset point, {bool mirrored = false}) {
    final s = scaleOf(size);
    final feet = seat(size, mirrored: mirrored);
    return Rect.fromLTRB(feet.dx - 62 * s, feet.dy - 150 * s, feet.dx + 62 * s, feet.dy + 6).contains(point);
  }

  final Map<String, TextPainter> _letters = {};

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame();
    final s = scaleOf(size);
    final feet = seat(size, mirrored: f.mirrored);
    _rug(canvas, size, feet, s);
    final breathe = f.alive ? math.sin(f.time * 2 * math.pi / 2.6) : 0.0;
    final sway = f.alive && f.face != RobotFace.asleep ? math.sin(f.time * 2 * math.pi / 3.4) * 0.03 : 0.0;
    final wiggleAt = f.trickAt(RobotTrick.wiggle);
    final wiggle = wiggleAt == null ? 0.0 : math.sin(wiggleAt * 2 * math.pi * 3.5) * 0.09 * (1 - wiggleAt);
    final yawnAt = f.trickAt(RobotTrick.yawn);
    final stretch = yawnAt == null ? 1.0 : 1 + 0.05 * math.sin(math.pi * yawnAt);
    final lift = f.hop * 26 * s;

    // The shadow shrinks as it hops.
    canvas.drawOval(
      Rect.fromCenter(center: feet + Offset(0, 4 * s), width: (78 - f.hop * 26) * s, height: 12 * s),
      Paint()..color = const Color(0x33000000),
    );

    canvas
      ..save()
      ..translate(feet.dx, feet.dy - lift)
      ..rotate(sway + wiggle)
      ..scale(s, s * stretch);
    if (f.mirrored) canvas.scale(-1, 1);
    _body(canvas, f, breathe);
    canvas.restore();

    if (f.face == RobotFace.asleep) {
      // Its sleep, rising over its head on the end side.
      final side = f.mirrored ? -1.0 : 1.0;
      for (var i = 0; i < 3; i++) {
        final z = _letter('z', 12.0 + i * 5, const Color(0x997a7a99));
        z.paint(canvas, feet + Offset(side * (52 + i * 14) * s - z.width / 2, -(150 + i * 16) * s));
      }
    }
    _particles(canvas, size, f);
  }

  void _rug(Canvas canvas, Size size, Offset feet, double s) {
    final rug = Rect.fromCenter(center: feet + Offset(0, 6 * s), width: 190 * s, height: 30 * s);
    final rr = RRect.fromRectAndRadius(rug, Radius.circular(6 * s));
    canvas
      ..drawRRect(rr, Paint()..color = RobotColors.rugA)
      ..drawRRect(rr.deflate(4 * s), Paint()..color = RobotColors.rugB)
      ..drawRRect(rr.deflate(8 * s), Paint()..color = RobotColors.rugA);
    // The rug's lozenges.
    final diamond = Paint()..color = RobotColors.rugC;
    for (var i = -3; i <= 3; i++) {
      final c = rug.center + Offset(i * 24 * s, 0);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 5 * s)
          ..lineTo(c.dx + 7 * s, c.dy)
          ..lineTo(c.dx, c.dy + 5 * s)
          ..lineTo(c.dx - 7 * s, c.dy)
          ..close(),
        diamond,
      );
    }
    // The fringe.
    final fringe = Paint()
      ..color = RobotColors.rugB
      ..strokeWidth = 1.4 * s;
    for (var y = rug.top + 4 * s; y < rug.bottom - 3 * s; y += 4 * s) {
      canvas
        ..drawLine(Offset(rug.left, y), Offset(rug.left - 5 * s, y), fringe)
        ..drawLine(Offset(rug.right, y), Offset(rug.right + 5 * s, y), fringe);
    }
  }

  /// The robot, its feet at the origin, in units of a stage 200 high.
  void _body(Canvas canvas, RobotFrame f, double breathe) {
    final happy = f.face == RobotFace.happy || f.face == RobotFace.eating;
    // Feet.
    final foot = Paint()..color = RobotColors.head;
    canvas
      ..drawRRect(RRect.fromLTRBR(-30, -10, -8, 2, const Radius.circular(6)), foot)
      ..drawRRect(RRect.fromLTRBR(8, -10, 30, 2, const Radius.circular(6)), foot);

    // Body, breathing.
    final grow = 1 + breathe * 0.015;
    canvas
      ..save()
      ..scale(grow, 1 / grow);
    final body = RRect.fromLTRBR(-36, -74, 36, -6, const Radius.circular(18));
    canvas
      ..drawRRect(
        body,
        Paint()
          ..shader = ui.Gradient.linear(const Offset(0, -74), const Offset(0, -6), const [
            RobotColors.bodyLight,
            RobotColors.body,
          ]),
      )
      // The belly: its level, in a teal plate.
      ..drawRRect(RRect.fromLTRBR(-18, -54, 18, -24, const Radius.circular(8)), Paint()..color = RobotColors.belly);
    final level = _letter('${f.level}', 17, const Color(0xfffdfbf7));
    level.paint(canvas, Offset(-level.width / 2, -39 - level.height / 2));
    canvas.restore();

    // Arms: they wave when it is happy.
    final wave = happy ? math.sin(f.time * 2 * math.pi / 0.5) * 0.5 : 0.0;
    final arm = Paint()..color = RobotColors.bodyLight;
    for (final side in [-1.0, 1.0]) {
      canvas
        ..save()
        ..translate(side * 37, -60)
        ..rotate(-side * (0.45 + (side > 0 ? wave : 0)))
        ..drawRRect(RRect.fromLTRBR(-6, 0, 6, 28, const Radius.circular(6)), arm)
        ..drawCircle(const Offset(0, 30), 6.5, Paint()..color = RobotColors.head)
        ..restore();
    }

    // Head.
    canvas
      ..save()
      ..translate(0, -78 + breathe * 1.2);
    final head = RRect.fromLTRBR(-44, -62, 44, 0, const Radius.circular(20));
    canvas
      ..drawRRect(head, Paint()..color = RobotColors.rim)
      ..drawRRect(head.deflate(4), Paint()..color = RobotColors.head);
    if (f.trickAt(RobotTrick.glitch) != null) {
      // A bad signal: the face jumps now and then, and splits into two ghosts, magenta and cyan.
      final jump = math.sin(f.time * 23) > 0.3 ? 1.0 : 0.0;
      final jitter = Offset(math.sin(f.time * 91) * 2.6, math.sin(f.time * 57) * 1.2) * jump;
      canvas
        ..save()
        ..clipRRect(head.deflate(4))
        ..save()
        ..translate(2.6 + jitter.dx, jitter.dy);
      _face(canvas, f, tint: const Color(0x88ff4fd8));
      canvas
        ..restore()
        ..save()
        ..translate(-2.6 + jitter.dx, jitter.dy);
      _face(canvas, f, tint: const Color(0x884fe8ff));
      canvas
        ..restore()
        ..save()
        ..translate(jitter.dx, 0);
      _face(canvas, f);
      canvas
        ..restore()
        ..restore();
    } else {
      _face(canvas, f);
    }
    _fez(canvas, f);
    canvas.restore();
  }

  /// The face on the screen; [tint] draws it in one colour, for the ghosts of a glitch.
  void _face(Canvas canvas, RobotFrame f, {Color? tint}) {
    final starry = f.trickAt(RobotTrick.starEyes) != null;
    final glowColour =
        tint ??
        (starry
            ? RobotColors.eyeWarm
            : switch (f.face) {
                RobotFace.happy || RobotFace.eating => RobotColors.eyeWarm,
                RobotFace.hallucinating => RobotColors.eyeOdd,
                RobotFace.cold => beadColour(0),
                _ => RobotColors.eye,
              });
    final gaping = f.trickAt(RobotTrick.fezFly) != null;
    final thinkingAt = f.trickAt(RobotTrick.thinking);
    final yawnAt = f.trickAt(RobotTrick.yawn);
    final eye = Paint()..color = glowColour;
    final line = Paint()
      ..color = glowColour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    // Thinking, it looks up and away; otherwise where the finger is.
    final look = thinkingAt != null
        ? const Offset(5, -4)
        : Offset(f.look.dx.clamp(-1, 1) * 6, f.look.dy.clamp(-1, 1) * 4);
    // The screen's glow.
    if (tint == null) {
      canvas.drawRRect(
        RRect.fromLTRBR(-34, -52, 34, -10, const Radius.circular(12)),
        Paint()..color = glowColour.withValues(alpha: 0.06),
      );
    }
    for (final side in [-1.0, 1.0]) {
      final centre = Offset(side * 16, -34) + look;
      if (gaping) {
        // Round eyes: its fez is gone.
        canvas
          ..drawCircle(centre, 7.5, eye)
          ..drawCircle(centre, 3, Paint()..color = RobotColors.head);
        continue;
      }
      if (starry) {
        canvas.drawPath(_star(centre, 9, 4), eye);
        continue;
      }
      if (yawnAt != null) {
        // Half shut, then a squeeze at the yawn's widest.
        final shut = 0.55 + 0.4 * math.sin(math.pi * yawnAt);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: centre, width: 10, height: 14 * (1 - shut)),
            const Radius.circular(5),
          ),
          eye,
        );
        continue;
      }
      switch (f.face) {
        case RobotFace.asleep:
          canvas.drawArc(Rect.fromCenter(center: centre, width: 14, height: 9), 0.2, math.pi - 0.4, false, line);
        case RobotFace.happy:
          canvas.drawArc(
            Rect.fromCenter(center: centre + const Offset(0, 3), width: 14, height: 12),
            math.pi + 0.3,
            math.pi - 0.6,
            false,
            line,
          );
        case RobotFace.overfit:
          // A spiral: it has learnt the tokens by heart.
          final spiral = Path()..moveTo(centre.dx, centre.dy);
          for (var a = 0.0; a < 4 * math.pi; a += 0.3) {
            final r = a * 0.62;
            spiral.lineTo(
              centre.dx + r * math.cos(a + f.time * 4 * side),
              centre.dy + r * math.sin(a + f.time * 4 * side),
            );
          }
          canvas.drawPath(spiral, line..strokeWidth = 2);
        case RobotFace.hallucinating:
          final r = side < 0 ? 7.5 : 4.0;
          canvas.drawCircle(centre, r * (1 - f.blink * 0.9), eye);
        case _:
          final h = 14 * (1 - f.blink * 0.88);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: centre, width: 10, height: h), const Radius.circular(5)),
            eye,
          );
          // A glint.
          if (f.blink < 0.5) {
            canvas.drawCircle(centre + const Offset(-2, -3), 1.6, Paint()..color = const Color(0xccffffff));
          }
      }
    }
    // Cheeks when happy, and when it blushes.
    if (tint == null && (f.face == RobotFace.happy || f.trickAt(RobotTrick.wiggle) != null)) {
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(side * 27, -22), width: 10, height: 6),
          Paint()..color = RobotColors.cheek,
        );
      }
    }
    // The mouth.
    final mouth = Offset(look.dx * 0.5, -18);
    final m = Paint()
      ..color = glowColour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    if (gaping) {
      canvas.drawOval(Rect.fromCenter(center: mouth, width: 9, height: 10), Paint()..color = glowColour);
      return;
    }
    if (yawnAt != null) {
      final open = 3 + 11 * math.sin(math.pi * yawnAt);
      canvas.drawOval(Rect.fromCenter(center: mouth, width: 11, height: open), Paint()..color = glowColour);
      return;
    }
    if (thinkingAt != null) {
      // Three dots in turn, as a model's reply waits.
      for (var i = 0; i < 3; i++) {
        final beat = math.sin((thinkingAt * 3 - i * 0.33) * 2 * math.pi);
        canvas.drawCircle(
          mouth + Offset((i - 1) * 7.0, -beat.clamp(0, 1) * 2),
          2.2,
          Paint()..color = glowColour.withValues(alpha: 0.35 + 0.65 * beat.clamp(0, 1)),
        );
      }
      return;
    }
    switch (f.face) {
      case RobotFace.eating:
        final open = 4 + 3 * math.sin(f.time * 2 * math.pi / 0.28).abs();
        canvas.drawOval(Rect.fromCenter(center: mouth, width: 9, height: open), Paint()..color = glowColour);
      case RobotFace.happy:
        canvas.drawArc(
          Rect.fromCenter(center: mouth - const Offset(0, 3), width: 16, height: 10),
          0.2,
          math.pi - 0.4,
          false,
          m,
        );
      case RobotFace.hungry:
        canvas.drawArc(
          Rect.fromCenter(center: mouth + const Offset(0, 4), width: 12, height: 8),
          math.pi + 0.3,
          math.pi - 0.6,
          false,
          m,
        );
      case RobotFace.asleep:
        canvas.drawCircle(mouth, 2, Paint()..color = glowColour);
      case RobotFace.overfit || RobotFace.hallucinating:
        final wave = Path()..moveTo(mouth.dx - 9, mouth.dy);
        for (var x = -9.0; x <= 9; x += 1.5) {
          wave.lineTo(mouth.dx + x, mouth.dy + math.sin(x * 0.9 + f.time * 6) * 2);
        }
        canvas.drawPath(wave, m);
      case RobotFace.calm || RobotFace.cold:
        canvas.drawArc(
          Rect.fromCenter(center: mouth - const Offset(0, 2), width: 12, height: 6),
          0.3,
          math.pi - 0.6,
          false,
          m,
        );
    }
  }

  void _fez(Canvas canvas, RobotFrame f) {
    // The fez sits tilted on the head; its tassel ends in the bead, which glows in the temperature's colour.
    // A hop turns it once in the air; a flight sends it high, spinning, and drops it back on.
    var lift = 0.0;
    var turn = 0.0;
    var drift = 0.0;
    if (f.trickAt(RobotTrick.fezHop) case final t?) {
      lift = math.sin(math.pi * t) * 24;
      turn = t * 2 * math.pi;
    }
    if (f.trickAt(RobotTrick.fezFly) case final t?) {
      lift = 4 * 70 * t * (1 - t);
      turn = t * 4 * math.pi;
      drift = math.sin(t * math.pi) * 16;
    }
    canvas
      ..save()
      ..translate(10 + drift, -60 - lift)
      ..translate(0, -10)
      ..rotate(0.16 + turn)
      ..translate(0, 10);
    final fez = Path()
      ..moveTo(-16, 2)
      ..lineTo(-12, -22)
      ..quadraticBezierTo(0, -26, 12, -22)
      ..lineTo(16, 2)
      ..quadraticBezierTo(0, 6, -16, 2)
      ..close();
    canvas
      ..drawPath(fez, Paint()..color = RobotColors.fez)
      ..drawPath(
        Path()
          ..moveTo(-15, -4)
          ..quadraticBezierTo(0, 0, 15, -4)
          ..lineTo(15.5, 0)
          ..quadraticBezierTo(0, 4, -15.5, 0)
          ..close(),
        Paint()..color = RobotColors.fezDark,
      );
    final swing = f.alive ? math.sin(f.time * 2 * math.pi / 1.6) * 3 : 0.0;
    var bead = Offset(19 + swing, -2);
    var bend = const Offset(14, -26);
    if (f.trickAt(RobotTrick.tasselSpin) case final t?) {
      // The bead swings round the fez's top, twice, on a taut cord.
      final a = 0.71 + t * 4 * math.pi;
      bead = const Offset(0, -24) + Offset(math.sin(a), math.cos(a)) * 27;
      bend = Offset.lerp(const Offset(0, -24), bead, 0.5)!;
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, -24)
        ..quadraticBezierTo(bend.dx, bend.dy, bead.dx, bead.dy - 4),
      Paint()
        ..color = RobotColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Thinking, the bead blinks.
    final thinking = f.trickAt(RobotTrick.thinking) != null;
    final colour = thinking && math.sin(f.time * 2 * math.pi * 4) < 0
        ? beadColour(f.temperature).withValues(alpha: 0.35)
        : beadColour(f.temperature);
    final pulse = f.alive ? 0.5 + 0.5 * math.sin(f.time * 2 * math.pi / 1.4) : 0.6;
    canvas
      ..drawCircle(
        bead,
        11 + pulse * 3,
        Paint()..shader = ui.Gradient.radial(bead, 14, [colour.withValues(alpha: 0.55), colour.withValues(alpha: 0)]),
      )
      ..drawCircle(bead, 4.6, Paint()..color = colour)
      ..drawCircle(bead - const Offset(1.4, 1.4), 1.4, Paint()..color = const Color(0xbbffffff))
      ..restore();
  }

  void _particles(Canvas canvas, Size size, RobotFrame f) {
    for (final p in f.particles) {
      final t = p.at(f.time);
      if (t == null) continue;
      final from = Offset(p.from.dx * size.width, p.from.dy * size.height);
      final to = Offset(p.to.dx * size.width, p.to.dy * size.height);
      switch (p.kind) {
        case ParticleKind.token:
          // An arc into the robot's mouth, or a whirl that closes on it, shrinking as it is swallowed.
          final e = Curves.easeInCubic.transform(t);
          final Offset pos;
          if (p.swirl > 0) {
            final a = p.spin + (1 - e) * 3 * math.pi;
            final r = p.swirl * size.width * (1 - e);
            pos = to + Offset(math.cos(a) * r, math.sin(a) * r * 0.6);
          } else {
            final control = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) - size.height * 0.45);
            pos = _quad(from, control, to, e);
          }
          final scale = t < 0.85 ? 1.0 : 1 - (t - 0.85) / 0.15;
          canvas
            ..save()
            ..translate(pos.dx, pos.dy)
            ..rotate(p.spin * t)
            ..scale(scale);
          final chip = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 22, height: 22),
            const Radius.circular(6),
          );
          canvas
            ..drawRRect(chip, Paint()..color = p.color)
            ..drawRRect(
              chip,
              Paint()
                ..color = RobotColors.ink.withValues(alpha: 0.5)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2,
            );
          final letter = _letter(p.label, 12, RobotColors.ink);
          letter.paint(canvas, Offset(-letter.width / 2, -letter.height / 2));
          canvas.restore();
        case ParticleKind.heart:
          final pos = Offset.lerp(from, to, Curves.easeOut.transform(t))! + Offset(math.sin(t * 9 + p.spin) * 8, 0);
          final alpha = t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8;
          _heart(canvas, pos, 9 + 4 * t, p.color.withValues(alpha: alpha.clamp(0, 1)));
        case ParticleKind.confetti:
          // Out and down, as thrown paper falls.
          final pos = Offset.lerp(from, to, Curves.easeOut.transform(t))! + Offset(0, t * t * size.height * 0.35);
          canvas
            ..save()
            ..translate(pos.dx, pos.dy)
            ..rotate(p.spin * t * 6)
            ..drawRect(
              Rect.fromCenter(center: Offset.zero, width: 7, height: 4),
              Paint()..color = p.color.withValues(alpha: (1 - t).clamp(0, 1)),
            )
            ..restore();
        case ParticleKind.spark:
          final pos = Offset.lerp(from, to, t)!;
          canvas.drawCircle(pos, 2.4 * (1 - t), Paint()..color = p.color.withValues(alpha: 1 - t));
        case ParticleKind.crumb:
          // Off the chin and down.
          final pos = Offset.lerp(from, to, t)! + Offset(0, t * t * size.height * 0.25);
          canvas.drawRect(
            Rect.fromCenter(center: pos, width: 3.2, height: 3.2),
            Paint()..color = p.color.withValues(alpha: (1 - t * t).clamp(0, 1)),
          );
        case ParticleKind.star:
          // A sparkle that swells and fades: a new word.
          final pos = Offset.lerp(from, to, t)!;
          final r = 7 * math.sin(math.pi * t);
          canvas.drawPath(_star(pos, r, r * 0.3, points: 4), Paint()..color = p.color.withValues(alpha: 1 - t * 0.5));
        case ParticleKind.frost:
          // A puff of cold breath, widening as it drifts.
          final pos = Offset.lerp(from, to, Curves.easeOut.transform(t))!;
          canvas.drawCircle(pos, 3 + 9 * t, Paint()..color = p.color.withValues(alpha: 0.8 * (1 - t)));
        case ParticleKind.burp:
          // A small bubble with the end of a sentence in it, rising and popping.
          final pos = Offset.lerp(from, to, Curves.easeOut.transform(t))!;
          final alpha = t < 0.85 ? 1.0 : 1 - (t - 0.85) / 0.15;
          final r = 13 + 3 * t;
          canvas
            ..drawCircle(pos, r, Paint()..color = const Color(0xfffdfbf7).withValues(alpha: 0.9 * alpha))
            ..drawCircle(
              pos,
              r,
              Paint()
                ..color = RobotColors.ink.withValues(alpha: 0.5 * alpha)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2,
            );
          final end = _letter(p.label, 8.5, RobotColors.ink);
          end.paint(canvas, pos - Offset(end.width / 2, end.height / 2));
      }
    }
  }

  /// A star of [points] points round [c], its tips at [outer] and its notches at [inner].
  static Path _star(Offset c, double outer, double inner, {int points = 5}) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final at = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(at.dx, at.dy) : path.lineTo(at.dx, at.dy);
    }
    return path..close();
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  static void _heart(Canvas canvas, Offset c, double r, Color colour) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.7)
      ..cubicTo(c.dx - r * 1.3, c.dy - r * 0.2, c.dx - r * 0.5, c.dy - r * 1.1, c.dx, c.dy - r * 0.35)
      ..cubicTo(c.dx + r * 0.5, c.dy - r * 1.1, c.dx + r * 1.3, c.dy - r * 0.2, c.dx, c.dy + r * 0.7)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }

  TextPainter _letter(String text, double size, Color colour) => _letters.putIfAbsent(
    '$text/$size/${colour.toARGB32()}',
    () => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: colour, fontSize: size, fontWeight: FontWeight.w800, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout(),
  );

  @override
  bool shouldRepaint(PocketRobotPainter old) => old.frame != frame;
}

/// The robot's head and fez alone, still, in the middle of its box: the face of the assistant button.
class RobotHeadPainter extends CustomPainter {
  RobotHeadPainter({required this.face, this.temperature = 0.8});

  final RobotFace face;
  final double temperature;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RobotFrame(
      time: 0,
      face: face,
      look: Offset.zero,
      blink: 0,
      hop: 0,
      temperature: temperature,
      level: 0,
      particles: const [],
      alive: false,
      mirrored: false,
    );
    final robot = PocketRobotPainter(frame: () => frame, repaint: const AlwaysStoppedAnimation(0));
    // The head and its fez stand in a box about 100 wide and 96 high, from the fez's top to the head's foot.
    final s = math.min(size.width / 100, size.height / 96);
    canvas
      ..save()
      ..translate(size.width / 2 - 2 * s, size.height / 2 + 46 * s)
      ..scale(s);
    final head = RRect.fromLTRBR(-44, -62, 44, 0, const Radius.circular(20));
    canvas
      ..drawRRect(head, Paint()..color = RobotColors.rim)
      ..drawRRect(head.deflate(4), Paint()..color = RobotColors.head);
    robot
      .._face(canvas, frame)
      .._fez(canvas, frame);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RobotHeadPainter old) => old.face != face || old.temperature != temperature;
}
