import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';

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

  /// Hello: it raises its arm and waves, as the app opens (the owner, 2026-11-14).
  wave,
}

/// How long each trick runs, in seconds.
abstract final class RobotTricks {
  static double length(RobotTrick trick) => switch (trick) {
    RobotTrick.wiggle => 0.9,
    RobotTrick.fezHop => 0.8,
    RobotTrick.fezFly => 1.5,
    RobotTrick.starEyes => 1.4,
    RobotTrick.tasselSpin => 1.2,
    RobotTrick.thinking => 0.35,
    RobotTrick.glitch => 1.6,
    RobotTrick.yawn => 1.5,
    RobotTrick.wave => 1.3,
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
    this.outfit = RobotOutfit.initial,
    this.hatRoom = PocketRobotPainter.hatRoom,
  });

  /// What it wears: its hat, the shape of its head and its body (plan 9.9).
  final RobotOutfit outfit;

  /// How far above its head its hat may reach ([PocketRobotPainter.hatScale]).
  final double hatRoom;

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
  PocketRobotPainter({required this.frame, required Listenable super.repaint, this.rug = true, this.centred = false});

  /// Reads the moment to draw; called on every paint.
  final RobotFrame Function() frame;

  /// Whether it sits on its rug, with its shadow; a wardrobe's small picture of a body has neither.
  final bool rug;

  /// Whether it stands in the middle of the stage, as where it says nothing ([seat]).
  final bool centred;

  /// Where the robot sits in a stage of [size]: the middle of its feet, past the middle toward the end side, so what it
  /// says has the start side; [centred], in the middle, where it says nothing (the wardrobe, the opening).
  static Offset seat(Size size, {bool mirrored = false, bool centred = false}) =>
      Offset(size.width * (centred ? 0.5 : (mirrored ? 0.28 : 0.72)), size.height - 30);

  /// The robot's scale in a stage of [size]: the same in every outfit, since a tall hat is drawn smaller instead
  /// ([hatScale]), so the robot itself never shrinks (the owner, 2026-11-14).
  static double scaleOf(Size size) => (size.height / 220).clamp(0.6, 1.3);

  /// Whether [point] is on the robot in a stage of [size].
  static bool hits(
    Size size,
    Offset point, {
    bool mirrored = false,
    bool centred = false,
    RobotOutfit outfit = RobotOutfit.initial,
  }) {
    final s = scaleOf(size);
    final feet = seat(size, mirrored: mirrored, centred: centred);
    return Rect.fromLTRB(feet.dx - 62 * s, feet.dy - 150 * s, feet.dx + 62 * s, feet.dy + 6).contains(point);
  }

  final Map<String, TextPainter> _letters = {};

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame();
    final s = scaleOf(size);
    final feet = seat(size, mirrored: f.mirrored, centred: centred);
    if (rug) _rug(canvas, size, feet, s);
    final breathe = f.alive ? math.sin(f.time * 2 * math.pi / 2.6) : 0.0;
    final sway = f.alive && f.face != RobotFace.asleep ? math.sin(f.time * 2 * math.pi / 3.4) * 0.03 : 0.0;
    final wiggleAt = f.trickAt(RobotTrick.wiggle);
    final wiggle = wiggleAt == null ? 0.0 : math.sin(wiggleAt * 2 * math.pi * 3.5) * 0.09 * (1 - wiggleAt);
    final yawnAt = f.trickAt(RobotTrick.yawn);
    final stretch = yawnAt == null ? 1.0 : 1 + 0.05 * math.sin(math.pi * yawnAt);
    final lift = f.hop * 26 * s;

    // The shadow shrinks as it hops.
    if (rug) {
      canvas.drawOval(
        Rect.fromCenter(center: feet + Offset(0, 4 * s), width: (78 - f.hop * 26) * s, height: 12 * s),
        Paint()..color = const Color(0x33000000),
      );
    }

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

    // A hood hangs behind the head.
    if (f.outfit.body == RobotBody.hoodie) _hood(canvas, breathe);

    // Body, breathing.
    final grow = 1 + breathe * 0.015;
    canvas
      ..save()
      ..scale(grow, 1 / grow);
    _torso(canvas, f);
    canvas.restore();

    // Arms: they wave when it is happy; saying hello, its end-side arm rises over its head and waves.
    final wave = happy ? math.sin(f.time * 2 * math.pi / 0.5) * 0.5 : 0.0;
    final helloAt = f.trickAt(RobotTrick.wave);
    // Up in the first fifth, waving, and down in the last.
    final raised = helloAt == null ? 0.0 : Curves.easeInOut.transform(math.min(1, math.min(helloAt, 1 - helloAt) * 5));
    final hello = helloAt == null ? 0.0 : raised * (2.1 + math.sin(helloAt * 2 * math.pi * 3) * 0.35);
    final look = _BodyLook.of(f.outfit.body);
    final arm = Paint()..color = look.arm;
    for (final side in [-1.0, 1.0]) {
      canvas
        ..save()
        ..translate(side * 37, -60)
        ..rotate(-side * (0.45 + (side > 0 ? (helloAt == null ? wave : hello) : 0)));
      if (f.outfit.body == RobotBody.kaftan) {
        // A wide sleeve.
        canvas.drawPath(
          Path()
            ..moveTo(-6, 0)
            ..lineTo(6, 0)
            ..lineTo(10, 24)
            ..quadraticBezierTo(0, 28, -10, 24)
            ..close(),
          arm,
        );
      } else {
        canvas.drawRRect(RRect.fromLTRBR(-6, 0, 6, 28, const Radius.circular(6)), arm);
      }
      if (look.cuff case final cuff?) {
        canvas.drawRect(const Rect.fromLTRB(-6, 19, 6, 23), Paint()..color = cuff);
      }
      canvas
        ..drawCircle(const Offset(0, 30), 6.5, Paint()..color = look.hand)
        ..restore();
    }

    // Head.
    canvas
      ..save()
      ..translate(0, -78 + breathe * 1.2);
    final head = _head(canvas, f.outfit.head);
    if (f.trickAt(RobotTrick.glitch) != null) {
      // A bad signal: the face jumps now and then, and splits into two ghosts, magenta and cyan.
      final jump = math.sin(f.time * 23) > 0.3 ? 1.0 : 0.0;
      final jitter = Offset(math.sin(f.time * 91) * 2.6, math.sin(f.time * 57) * 1.2) * jump;
      canvas
        ..save()
        ..clipRRect(head)
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
    if (f.outfit.head == RobotHead.visor) _glass(canvas);
    _hat(canvas, f);
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
        final beat = math.sin((thinkingAt * 2 - i * 0.33) * 2 * math.pi);
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

  /// The head's outline for [shape], drawn with its rim; returns the screen, where the face goes.
  static RRect _head(Canvas canvas, RobotHead shape) {
    switch (shape) {
      case RobotHead.dome:
        final head = RRect.fromLTRBXY(-44, -62, 44, 0, 40, 30);
        canvas
          ..drawRRect(head, Paint()..color = RobotColors.rim)
          ..drawRRect(head.deflate(4), Paint()..color = RobotColors.head);
        return head.deflate(4);
      case RobotHead.tv:
        // A wooden case, a curved glass screen, two knobs on its side.
        final caseBox = RRect.fromLTRBR(-48, -63, 48, 1, const Radius.circular(7));
        canvas
          ..drawRRect(caseBox, Paint()..color = const Color(0xff6e4630))
          ..drawRRect(caseBox.deflate(2.5), Paint()..color = const Color(0xff8a5a3a));
        final screen = RRect.fromLTRBR(-40, -57, 36, -5, const Radius.circular(12));
        canvas
          ..drawRRect(screen.inflate(2), Paint()..color = const Color(0xff2a2a30))
          ..drawRRect(screen, Paint()..color = RobotColors.head);
        for (final y in [-44.0, -28.0]) {
          canvas
            ..drawCircle(Offset(42, y), 3.6, Paint()..color = const Color(0xffd9c9a8))
            ..drawLine(
              Offset(42, y),
              Offset(42, y - 3),
              Paint()
                ..color = const Color(0xff4a3020)
                ..strokeWidth = 1.2,
            );
        }
        return screen;
      case RobotHead.ears:
        for (final side in [-1.0, 1.0]) {
          final ear = Path()
            ..moveTo(side * 40, -46)
            ..lineTo(side * 38, -78)
            ..lineTo(side * 14, -60)
            ..close();
          final inner = Path()
            ..moveTo(side * 35, -52)
            ..lineTo(side * 34.5, -71)
            ..lineTo(side * 21, -61)
            ..close();
          canvas
            ..drawPath(ear, Paint()..color = RobotColors.rim)
            ..drawPath(inner, Paint()..color = const Color(0xffe89aa8));
        }
        final head = RRect.fromLTRBR(-44, -62, 44, 0, const Radius.circular(20));
        canvas
          ..drawRRect(head, Paint()..color = RobotColors.rim)
          ..drawRRect(head.deflate(4), Paint()..color = RobotColors.head);
        return head.deflate(4);
      case RobotHead.classic || RobotHead.visor:
        final head = RRect.fromLTRBR(-44, -62, 44, 0, const Radius.circular(20));
        canvas
          ..drawRRect(head, Paint()..color = RobotColors.rim)
          ..drawRRect(head.deflate(4), Paint()..color = RobotColors.head);
        return head.deflate(4);
    }
  }

  /// A space helmet's glass round the head, with a collar at its foot.
  static void _glass(Canvas canvas, {bool collar = true}) {
    // An oval close round the head, so it adds little above it and the robot keeps its size in it.
    final glass = Rect.fromCenter(center: const Offset(0, -31), width: 108, height: 84);
    canvas
      ..drawOval(glass, Paint()..color = const Color(0x1fbfe8ff))
      ..drawOval(
        glass,
        Paint()
          ..color = const Color(0x99dff4ff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      )
      ..drawArc(
        glass.deflate(9),
        math.pi * 1.08,
        math.pi * 0.42,
        false,
        Paint()
          ..color = const Color(0xb3ffffff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    if (collar) {
      canvas.drawRRect(
        RRect.fromLTRBR(-30, 12, 30, 20, const Radius.circular(4)),
        Paint()..color = const Color(0xffcfd2d6),
      );
    }
  }

  /// How far above the head's top [hat] sits on [head]: on a helmet, on its glass.
  static double _hatSeat(RobotHead head) => head == RobotHead.visor ? 12 : 0;

  /// How far above the head's top any hat reaches, with its seat: a hat that would reach higher is drawn smaller.
  static const hatRoom = 44.0;

  /// The scale [hat] is drawn at on [head], so it reaches no higher than [room].
  static double hatScale(RobotHead head, RobotHat hat, {double room = hatRoom}) =>
      math.min(1, (room - _hatSeat(head)) / hatHeight(hat));

  /// The room for a hat on an app icon, where the head stands alone and a tall hat may stand taller.
  static const iconHatRoom = 56.0;

  /// How far [hat] reaches above its seat, with its bead's glow.
  static double hatHeight(RobotHat hat) => switch (hat) {
    RobotHat.fez => 30,
    RobotHat.antenna => 36,
    RobotHat.beanie => 42,
    RobotHat.mortarboard => 28,
    RobotHat.turban => 44,
    RobotHat.wizard => 76,
    RobotHat.topHat => 50,
    RobotHat.crown => 34,
  };

  void _hat(Canvas canvas, RobotFrame f) {
    // The hat sits on the head, the fez tilted; its bead glows in the temperature's colour. A hop turns it once in the
    // air; a flight sends it high, spinning, and drops it back on.
    final hat = f.outfit.hat;
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
    final (dx, tilt) = switch (hat) {
      RobotHat.fez => (10.0, 0.16),
      RobotHat.antenna => (0.0, 0.0),
      RobotHat.beanie => (0.0, 0.05),
      RobotHat.mortarboard => (0.0, -0.06),
      RobotHat.turban => (0.0, 0.0),
      RobotHat.wizard => (2.0, -0.08),
      RobotHat.topHat => (6.0, 0.1),
      RobotHat.crown => (0.0, 0.06),
    };
    canvas
      ..save()
      ..translate(dx + drift, -60 - lift - _hatSeat(f.outfit.head))
      ..translate(0, -10)
      ..rotate(tilt + turn)
      ..translate(0, 10)
      ..scale(hatScale(f.outfit.head, hat, room: f.hatRoom));
    final swing = f.alive ? math.sin(f.time * 2 * math.pi / 1.6) * 3 : 0.0;
    switch (hat) {
      case RobotHat.fez:
        canvas
          ..drawPath(
            Path()
              ..moveTo(-16, 2)
              ..lineTo(-12, -22)
              ..quadraticBezierTo(0, -26, 12, -22)
              ..lineTo(16, 2)
              ..quadraticBezierTo(0, 6, -16, 2)
              ..close(),
            Paint()..color = RobotColors.fez,
          )
          ..drawPath(
            Path()
              ..moveTo(-15, -4)
              ..quadraticBezierTo(0, 0, 15, -4)
              ..lineTo(15.5, 0)
              ..quadraticBezierTo(0, 4, -15.5, 0)
              ..close(),
            Paint()..color = RobotColors.fezDark,
          );
        _tassel(canvas, f, from: const Offset(0, -24), rest: Offset(19 + swing, -2), bend: const Offset(14, -26));
      case RobotHat.antenna:
        // A springy stalk, swaying, its bead at the tip.
        final tip = Offset(swing * 1.4, -26);
        canvas
          ..drawRRect(RRect.fromLTRBR(-8, -3, 8, 3, const Radius.circular(3)), Paint()..color = RobotColors.rim)
          ..drawPath(
            Path()
              ..moveTo(0, -2)
              ..quadraticBezierTo(tip.dx * 0.2, -14, tip.dx, tip.dy),
            Paint()
              ..color = const Color(0xff8a8e9a)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.6
              ..strokeCap = StrokeCap.round,
          );
        _bead(canvas, f, tip, radius: 5);
      case RobotHat.beanie:
        const knit = Color(0xffc9893a);
        const band = Color(0xffa86e2a);
        canvas.drawPath(
          Path()
            ..moveTo(-42, 4)
            ..cubicTo(-42, -28, 42, -28, 42, 4)
            ..close(),
          Paint()..color = knit,
        );
        final rib = Paint()
          ..color = band.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        for (var x = -30.0; x <= 30; x += 10) {
          canvas.drawLine(Offset(x, -1), Offset(x * 0.55, -16 + (x.abs() / 30) * 6), rib);
        }
        canvas.drawRRect(RRect.fromLTRBR(-43, -4, 43, 6, const Radius.circular(4)), Paint()..color = band);
        for (var x = -38.0; x <= 38; x += 5) {
          canvas.drawLine(Offset(x, -3), Offset(x, 5), rib);
        }
        _bead(canvas, f, const Offset(0, -24), radius: 7.5, glow: 0.8);
      case RobotHat.mortarboard:
        const ink = Color(0xff1f2030);
        canvas
          ..drawPath(
            Path()
              ..moveTo(-24, 4)
              ..lineTo(-22, -8)
              ..lineTo(22, -8)
              ..lineTo(24, 4)
              ..quadraticBezierTo(0, 8, -24, 4)
              ..close(),
            Paint()..color = ink,
          )
          ..drawPath(
            Path()
              ..moveTo(-40, -12)
              ..lineTo(0, -24)
              ..lineTo(40, -12)
              ..lineTo(0, -1)
              ..close(),
            Paint()..color = const Color(0xff2c2e42),
          )
          ..drawCircle(const Offset(0, -12), 2.4, Paint()..color = const Color(0xffddb46a));
        _tassel(
          canvas,
          f,
          from: const Offset(0, -12),
          rest: Offset(37 + swing * 0.6, 12),
          bend: const Offset(36, -10),
          cord: const Color(0xffddb46a),
        );
      case RobotHat.turban:
        const cloth = Color(0xfff0e6d2);
        const fold = Color(0xffcdbf9f);
        canvas
          ..drawOval(Rect.fromCenter(center: const Offset(0, -20), width: 66, height: 30), Paint()..color = cloth)
          ..drawOval(Rect.fromCenter(center: const Offset(0, -6), width: 94, height: 26), Paint()..color = cloth);
        final wrap = Paint()
          ..color = fold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          canvas.drawArc(
            Rect.fromCenter(center: Offset(-6.0 + i * 4, -10 - i * 5), width: 80 - i * 12, height: 18),
            math.pi * 0.05,
            math.pi * 0.8,
            false,
            wrap,
          );
        }
        // A plume over the jewel.
        canvas.drawPath(
          Path()
            ..moveTo(0, -12)
            ..quadraticBezierTo(-10, -30, 6 + swing, -40)
            ..quadraticBezierTo(4, -24, 3, -12)
            ..close(),
          Paint()..color = RobotColors.belly,
        );
        _bead(canvas, f, const Offset(0, -9), radius: 5.2);
      case RobotHat.wizard:
        const cloth = Color(0xff2a3a8a);
        canvas
          ..drawOval(Rect.fromCenter(center: const Offset(0, 2), width: 100, height: 14), Paint()..color = cloth)
          ..drawPath(
            Path()
              ..moveTo(-32, 2)
              ..quadraticBezierTo(-12, -30, 6, -60)
              ..quadraticBezierTo(14, -66, 20 + swing, -62)
              ..quadraticBezierTo(14, -52, 12, -46)
              ..quadraticBezierTo(18, -20, 32, 2)
              ..close(),
            Paint()..color = const Color(0xff33479e),
          )
          ..drawRect(const Rect.fromLTRB(-30, -6, 30, 0), Paint()..color = const Color(0xffddb46a));
        for (final (at, r) in [
          (const Offset(-10, -20), 3.0),
          (const Offset(8, -34), 2.4),
          (const Offset(14, -12), 2.0),
        ]) {
          canvas.drawPath(_star(at, r * 1.6, r * 0.6), Paint()..color = const Color(0xffffe7a6));
        }
        _bead(canvas, f, Offset(21 + swing, -62), radius: 4.6, star: true);
      case RobotHat.topHat:
        const silk = Color(0xff16161c);
        canvas
          ..drawOval(Rect.fromCenter(center: const Offset(0, 2), width: 84, height: 12), Paint()..color = silk)
          ..drawRRect(RRect.fromLTRBR(-24, -46, 24, 2, const Radius.circular(3)), Paint()..color = silk)
          ..drawOval(
            Rect.fromCenter(center: const Offset(0, -46), width: 48, height: 8),
            Paint()..color = const Color(0xff2a2a34),
          )
          ..drawRect(const Rect.fromLTRB(-24, -12, 24, -3), Paint()..color = const Color(0xff8e1f26))
          ..drawLine(
            const Offset(-18, -42),
            const Offset(-18, -16),
            Paint()
              ..color = const Color(0x22ffffff)
              ..strokeWidth = 3,
          );
        _bead(canvas, f, const Offset(13, -7.5), radius: 4);
      case RobotHat.crown:
        const gold = Color(0xffe2b23c);
        const shade = Color(0xffb8862a);
        final crown = Path()..moveTo(-34, 4);
        const points = [(-34.0, -24.0), (-17.0, -12.0), (0.0, -30.0), (17.0, -12.0), (34.0, -24.0)];
        crown.lineTo(-34, -24);
        for (var i = 1; i < points.length; i++) {
          final (x, y) = points[i];
          final (px, _) = points[i - 1];
          crown
            ..lineTo((x + px) / 2, -8)
            ..lineTo(x, y);
        }
        crown
          ..lineTo(34, 4)
          ..close();
        canvas
          ..drawPath(crown, Paint()..color = gold)
          ..drawRect(const Rect.fromLTRB(-34, -4, 34, 4), Paint()..color = shade);
        for (final (x, y) in points) {
          canvas.drawCircle(Offset(x, y - 2), 3, Paint()..color = x == 0 ? const Color(0xfffdfbf7) : RobotColors.rugA);
        }
        _bead(canvas, f, const Offset(0, -8), radius: 5);
    }
    canvas.restore();
  }

  /// A cord from [from] to the bead, which hangs at [rest] through [bend]; a spin swings it round [from] on a taut
  /// cord.
  void _tassel(
    Canvas canvas,
    RobotFrame f, {
    required Offset from,
    required Offset rest,
    required Offset bend,
    Color cord = RobotColors.ink,
  }) {
    var bead = rest;
    var through = bend;
    if (f.trickAt(RobotTrick.tasselSpin) case final t?) {
      final reach = (rest - from).distance;
      final start = math.atan2(rest.dx - from.dx, rest.dy - from.dy);
      final a = start + t * 4 * math.pi;
      bead = from + Offset(math.sin(a), math.cos(a)) * reach;
      through = Offset.lerp(from, bead, 0.5)!;
    }
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(through.dx, through.dy, bead.dx, bead.dy - 4),
      Paint()
        ..color = cord
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    _bead(canvas, f, bead);
  }

  /// The bead at [at], glowing in the temperature's colour; it blinks while the robot thinks. [star] makes it a star.
  void _bead(Canvas canvas, RobotFrame f, Offset at, {double radius = 4.6, double glow = 1, bool star = false}) {
    final thinking = f.trickAt(RobotTrick.thinking) != null;
    final colour = thinking && math.sin(f.time * 2 * math.pi * 4) < 0
        ? beadColour(f.temperature).withValues(alpha: 0.35)
        : beadColour(f.temperature);
    final pulse = f.alive ? 0.5 + 0.5 * math.sin(f.time * 2 * math.pi / 1.4) : 0.6;
    final halo = (radius * 2.4 + pulse * 3) * glow;
    canvas.drawCircle(
      at,
      halo,
      Paint()..shader = ui.Gradient.radial(at, halo, [colour.withValues(alpha: 0.55), colour.withValues(alpha: 0)]),
    );
    if (star) {
      canvas.drawPath(_star(at, radius * 1.7, radius * 0.7), Paint()..color = colour);
    } else {
      canvas
        ..drawCircle(at, radius, Paint()..color = colour)
        ..drawCircle(at - Offset(radius * 0.3, radius * 0.3), radius * 0.3, Paint()..color = const Color(0xbbffffff));
    }
  }

  /// A hood behind the head, at the neck.
  static void _hood(Canvas canvas, double breathe) {
    final look = _BodyLook.of(RobotBody.hoodie);
    canvas.drawPath(
      Path()
        ..moveTo(-40, -66)
        ..quadraticBezierTo(-50, -100 + breathe, -30, -118)
        ..lineTo(30, -118)
        ..quadraticBezierTo(50, -100 + breathe, 40, -66)
        ..close(),
      Paint()..color = look.dark,
    );
  }

  /// The body for its outfit, its feet at the origin: its level on a plate at the chest.
  void _torso(Canvas canvas, RobotFrame f) {
    final body = f.outfit.body;
    final look = _BodyLook.of(body);
    final shell = RRect.fromLTRBR(-36, -74, 36, -6, const Radius.circular(18));
    final fill = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, -74), const Offset(0, -6), [look.light, look.dark]);
    var plate = RRect.fromLTRBR(-18, -54, 18, -24, const Radius.circular(8));
    var plateColour = RobotColors.belly;
    var levelColour = const Color(0xfffdfbf7);
    switch (body) {
      case RobotBody.classic:
        canvas.drawRRect(shell, fill);
      case RobotBody.vest:
        canvas.drawRRect(shell, fill);
        // Two embroidered panels, open over the plate.
        final panel = Paint()..color = RobotColors.fez;
        final trim = Paint()
          ..color = const Color(0xffddb46a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        for (final side in [-1.0, 1.0]) {
          final path = Path()
            ..moveTo(side * 36, -60)
            ..lineTo(side * 22, -72)
            ..lineTo(side * 20, -58)
            ..lineTo(side * 21, -14)
            ..lineTo(side * 36, -14)
            ..close();
          canvas
            ..save()
            ..clipRRect(shell)
            ..drawPath(path, panel)
            ..drawPath(path, trim)
            ..restore();
          for (var y = -48.0; y <= -22; y += 9) {
            canvas.drawPath(_star(Offset(side * 29, y), 2.6, 1.1, points: 4), Paint()..color = const Color(0xffddb46a));
          }
        }
      case RobotBody.hoodie:
        canvas.drawRRect(shell, fill);
        // A front pocket and the hood's cords.
        canvas.drawRRect(RRect.fromLTRBR(-24, -24, 24, -9, const Radius.circular(6)), Paint()..color = look.dark);
        final string = Paint()
          ..color = const Color(0xfff4f1ea)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(const Offset(-7, -72), const Offset(-9, -58), string)
          ..drawLine(const Offset(7, -72), const Offset(9, -58), string);
        plate = RRect.fromLTRBR(-14, -54, 14, -30, const Radius.circular(7));
      case RobotBody.labCoat:
        // A white coat over its navy body, open at the front.
        canvas
          ..drawRRect(shell, Paint()..color = RobotColors.body)
          ..save()
          ..clipRRect(shell);
        for (final side in [-1.0, 1.0]) {
          canvas
            ..drawPath(
              Path()
                ..moveTo(side * 40, -76)
                ..lineTo(side * 10, -76)
                ..lineTo(side * 20, -50)
                ..lineTo(side * 19, -4)
                ..lineTo(side * 40, -4)
                ..close(),
              fill,
            )
            // The lapel.
            ..drawPath(
              Path()
                ..moveTo(side * 10, -76)
                ..lineTo(side * 20, -50)
                ..lineTo(side * 25, -66)
                ..close(),
              Paint()..color = look.dark,
            );
        }
        canvas
          ..restore()
          // A pocket with a pen.
          ..drawRect(const Rect.fromLTRB(-33, -40, -23, -30), Paint()..color = look.dark)
          ..drawLine(
            const Offset(-26, -44),
            const Offset(-26, -34),
            Paint()
              ..color = RobotColors.rugA
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round,
          );
        plate = RRect.fromLTRBR(-12, -50, 12, -28, const Radius.circular(6));
      case RobotBody.kaftan:
        // A long robe, wider at the hem, with a gold trim and a sash.
        final robe = Path()
          ..moveTo(-30, -74)
          ..lineTo(30, -74)
          ..quadraticBezierTo(38, -72, 38, -62)
          ..lineTo(46, -2)
          ..quadraticBezierTo(0, 4, -46, -2)
          ..lineTo(-38, -62)
          ..quadraticBezierTo(-38, -72, -30, -74)
          ..close();
        canvas
          ..drawPath(robe, fill)
          ..drawPath(
            robe,
            Paint()
              ..color = const Color(0xffddb46a)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          )
          ..drawLine(
            const Offset(0, -74),
            const Offset(0, -2),
            Paint()
              ..color = const Color(0xffddb46a)
              ..strokeWidth = 1.6,
          )
          ..drawRect(const Rect.fromLTRB(-40, -22, 40, -15), Paint()..color = const Color(0xffddb46a));
        plate = RRect.fromLTRBR(-15, -56, 15, -30, const Radius.circular(7));
      case RobotBody.suit:
        canvas.drawRRect(shell, fill);
        // A white shirt in the jacket's V, and a bow tie.
        canvas
          ..save()
          ..clipRRect(shell)
          ..drawPath(
            Path()
              ..moveTo(-16, -76)
              ..lineTo(16, -76)
              ..lineTo(0, -56)
              ..close(),
            Paint()..color = const Color(0xfff4f1ea),
          )
          ..restore();
        final bow = Paint()..color = RobotColors.rugA;
        canvas
          ..drawPath(
            Path()
              ..moveTo(0, -70)
              ..lineTo(-10, -76)
              ..lineTo(-10, -64)
              ..close(),
            bow,
          )
          ..drawPath(
            Path()
              ..moveTo(0, -70)
              ..lineTo(10, -76)
              ..lineTo(10, -64)
              ..close(),
            bow,
          )
          ..drawCircle(const Offset(0, -70), 2.6, bow);
        for (final y in [-30.0, -18.0]) {
          canvas.drawCircle(Offset(0, y), 1.8, Paint()..color = const Color(0xff9a9ea8));
        }
        plate = RRect.fromLTRBR(14, -52, 30, -42, const Radius.circular(3));
        plateColour = const Color(0xffddb46a);
        levelColour = RobotColors.ink;
      case RobotBody.astronaut:
        canvas.drawRRect(shell, fill);
        // Its suit's seams, a belt and a panel of buttons with its level.
        final seam = Paint()
          ..color = look.dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas
          ..drawRRect(
            RRect.fromLTRBR(-36, -18, 36, -10, const Radius.circular(3)),
            Paint()..color = const Color(0xff9a9ea8),
          )
          ..drawLine(const Offset(-26, -70), const Offset(-26, -20), seam)
          ..drawLine(const Offset(26, -70), const Offset(26, -20), seam);
        plate = RRect.fromLTRBR(-18, -58, 18, -26, const Radius.circular(5));
        plateColour = const Color(0xff3a3d46);
        for (final (x, colour) in [
          (-10.0, RobotColors.rugA),
          (0.0, const Color(0xffddb46a)),
          (10.0, RobotColors.belly),
        ]) {
          canvas.drawCircle(Offset(x, -21.5), 2, Paint()..color = colour);
        }
    }
    canvas.drawRRect(plate, Paint()..color = plateColour);
    final size = plate.height < 16 ? 8.0 : 17.0;
    final level = _letter('${f.level}', size, levelColour);
    level.paint(canvas, plate.center - Offset(level.width / 2, level.height / 2));
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

/// The colours of a body: its gradient, its arms, its hands, and a cuff when its sleeves have one.
final class _BodyLook {
  const _BodyLook({
    required this.light,
    required this.dark,
    required this.arm,
    this.hand = RobotColors.head,
    this.cuff,
  });

  final Color light;
  final Color dark;
  final Color arm;
  final Color hand;
  final Color? cuff;

  static _BodyLook of(RobotBody body) => switch (body) {
    RobotBody.classic ||
    RobotBody.vest => const _BodyLook(light: RobotColors.bodyLight, dark: RobotColors.body, arm: RobotColors.bodyLight),
    RobotBody.hoodie => const _BodyLook(light: Color(0xff6b8a78), dark: Color(0xff4a6656), arm: Color(0xff5f7d6b)),
    RobotBody.labCoat => const _BodyLook(
      light: Color(0xfff6f3ec),
      dark: Color(0xffd6d1c4),
      arm: Color(0xffeae6dc),
      cuff: Color(0xffd6d1c4),
    ),
    RobotBody.kaftan => const _BodyLook(
      light: Color(0xff7a4589),
      dark: Color(0xff4f2a5c),
      arm: Color(0xff6a3a78),
      cuff: Color(0xffddb46a),
    ),
    RobotBody.suit => const _BodyLook(
      light: Color(0xff464a55),
      dark: Color(0xff272a31),
      arm: Color(0xff3c3f49),
      cuff: Color(0xfff4f1ea),
    ),
    RobotBody.astronaut => const _BodyLook(
      light: Color(0xfff2f2ee),
      dark: Color(0xffc9ccd1),
      arm: Color(0xffe6e7e4),
      hand: Color(0xffe0703c),
      cuff: Color(0xffe0703c),
    ),
  };
}

/// The robot's head and hat alone, still, in the middle of its box: the face of the assistant button, and a picture of
/// a hat or a head in the wardrobe.
class RobotHeadPainter extends CustomPainter {
  RobotHeadPainter({required this.face, this.temperature = 0.8, this.outfit = RobotOutfit.initial, this.tight = false});

  final RobotFace face;
  final double temperature;
  final RobotOutfit outfit;

  /// Whether its box reaches only as high as its own hat does, so it fills the picture whatever it wears: an app icon
  /// (the owner, 2026-11-14: the head had looked small on the home screen). Otherwise the box has room for the tallest
  /// hat, so heads side by side are the same size.
  final bool tight;

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
      outfit: outfit,
      hatRoom: tight ? PocketRobotPainter.iconHatRoom : PocketRobotPainter.hatRoom,
    );
    final robot = PocketRobotPainter(frame: () => frame, repaint: const AlwaysStoppedAnimation(0));
    // The head and its hat stand in the same box in every outfit, from the highest a hat reaches to the head's foot,
    // as wide as a helmet's glass, so the head is the same size whatever it wears.
    final visor = outfit.head == RobotHead.visor;
    final top = tight
        ? 62 +
              PocketRobotPainter._hatSeat(outfit.head) +
              PocketRobotPainter.hatHeight(outfit.hat) *
                  PocketRobotPainter.hatScale(outfit.head, outfit.hat, room: frame.hatRoom)
        : 62 + PocketRobotPainter.hatRoom;
    const bottom = 12.0;
    const width = 112.0;
    final s = math.min(size.width / width, size.height / (top + bottom));
    canvas
      ..save()
      ..translate(size.width / 2 - 2 * s, size.height / 2 + (top - bottom) / 2 * s)
      ..scale(s);
    PocketRobotPainter._head(canvas, outfit.head);
    robot._face(canvas, frame);
    if (visor) PocketRobotPainter._glass(canvas, collar: false);
    robot._hat(canvas, frame);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RobotHeadPainter old) =>
      old.face != face || old.temperature != temperature || old.outfit != outfit || old.tight != tight;
}
