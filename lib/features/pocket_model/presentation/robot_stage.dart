import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/shared/robot_level/robot_level_cubit.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What flies when the robot is pleased, shared by the pocket model's sheet and [RobotStage]: positions are fractions
/// of the stage, times seconds on its clock.
abstract final class RobotMoves {
  /// Four hearts rising from over its [head], from [time].
  static List<Particle> hearts(Offset head, double time) => [
    for (var i = 0; i < 4; i++)
      Particle(
        kind: ParticleKind.heart,
        born: time + i * 0.12,
        life: 1.3,
        from: head + Offset((i - 1.5) * 0.06, 0),
        to: head + Offset((i - 1.5) * 0.1, -0.35),
        color: const Color(0xffe0607a),
        spin: i.toDouble(),
      ),
  ];

  /// [count] stars twinkling [around] a point, from [time].
  static List<Particle> sparkles(int count, Offset around, double time, math.Random random) => [
    for (var i = 0; i < count; i++)
      if (random.nextDouble() * 2 * math.pi case final a)
        Particle(
          kind: ParticleKind.star,
          born: time + i * 0.1,
          life: 0.8,
          from: around + Offset(math.cos(a) * 0.1, math.sin(a) * 0.12),
          to: around + Offset(math.cos(a) * 0.1, math.sin(a) * 0.12 - 0.05),
          color: const Color(0xffffd88a),
        ),
  ];

  /// Five notes of a hum rising from beside its [mouth], one after another from [time].
  static List<Particle> notes(Offset mouth, double time, math.Random random, {bool mirrored = false}) => [
    for (var i = 0; i < 5; i++)
      Particle(
        kind: ParticleKind.note,
        born: time + 0.15 + i * 0.28,
        life: 1.1,
        from: mouth + Offset((mirrored ? -1 : 1) * 0.06, -0.04),
        to: mouth + Offset((mirrored ? -1 : 1) * (0.12 + random.nextDouble() * 0.1), -0.3 - random.nextDouble() * 0.08),
        color: const [Color(0xff7a4a86), Color(0xff2f8c86), Color(0xffc9785f)][i % 3],
        spin: i * 1.7,
      ),
  ];

  /// Where its mouth is on a stage of [size], as a fraction of it.
  static Offset mouth(Size size, {bool mirrored = false, bool centred = false}) {
    if (size.isEmpty) return const Offset(0.5, 0.5);
    final seat = PocketRobotPainter.seat(size, mirrored: mirrored, centred: centred);
    final at = seat - Offset(0, 96 * PocketRobotPainter.scaleOf(size));
    return Offset(at.dx / size.width, at.dy / size.height);
  }
}

/// The greetings the robot opens the app with (the owner, 2026-11-14): one at random each time, each short, and most of
/// them sweet.
enum RobotHello { wave, hearts, starEyes, hatHop, wiggle, twirl, bounce, heartEyes, hum }

/// The robot alone in the middle of a stage, in what it wears at the pocket model's level: the wardrobe's robot and the
/// app's opening (plan 9.10). It blinks now and then and breathes for a while after a touch; a tap on it pets it as
/// the pocket model's sheet does: one of eight turns at random, and three pets in a row send its hat flying.
///
/// With [hello] it greets as it appears, one of [RobotHello] at random, and calls [onHello] when it is done. Under
/// reduced motion it stands still, and [onHello] comes on the first frame.
class RobotStage extends StatefulWidget {
  const RobotStage({super.key, this.outfit, this.rug = true, this.hello = false, this.onHello, this.random});

  /// What it wears; null, what the reader chose for it at the model's level.
  final RobotOutfit? outfit;

  /// Whether it stands on its rug.
  final bool rug;

  final bool hello;
  final VoidCallback? onHello;

  /// Draws its turns; a test passes a seeded one.
  final math.Random? random;

  /// How long a greeting lasts, at most: the opening is about a second in all (the owner, 2026-11-14).
  static const helloLength = Duration(milliseconds: 850);

  /// How much faster than its own clock a greeting plays, so a turn made for a pet fits in [helloLength].
  static const helloPace = 1.6;

  @override
  State<RobotStage> createState() => RobotStageState();
}

class RobotStageState extends State<RobotStage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final math.Random _random = widget.random ?? math.Random();
  Timer? _blinker;
  Timer? _greeted;

  /// Whether it is greeting now, its clock running faster.
  bool _greeting = false;

  double _time = 0;
  Duration _lastElapsed = Duration.zero;
  double _activeUntil = 0;
  double? _blinkAt;
  double? _hopAt;
  double? _joyAt;
  final List<(RobotTrick, double)> _tricks = [];
  final List<double> _pets = [];
  final List<Particle> _particles = [];
  Size _stage = Size.zero;
  RobotOutfit _outfit = RobotOutfit.initial;
  int _level = 0;

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
    if (widget.hello) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_reduced) {
          widget.onHello?.call();
          return;
        }
        _greeting = true;
        greet(RobotHello.values[_random.nextInt(RobotHello.values.length)]);
        _greeted = Timer(RobotStage.helloLength, () {
          _greeting = false;
          if (mounted) widget.onHello?.call();
        });
      });
    }
  }

  @override
  void dispose() {
    _blinker?.cancel();
    _greeted?.cancel();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _scheduleBlink() {
    _blinker = Timer(Duration(milliseconds: 3200 + _random.nextInt(2600)), () {
      if (!mounted) return;
      if (!_reduced) {
        _blinkAt = _time;
        _wake(lively: false);
      }
      _scheduleBlink();
    });
  }

  void _wake({bool lively = true}) {
    if (lively) _activeUntil = _time + 8;
    if (_reduced) {
      _frame.value++;
      return;
    }
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _time += dt.clamp(0, 0.1) * (_greeting ? RobotStage.helloPace : 1);
    _particles.removeWhere((p) => _time > p.born + p.life);
    final busy =
        _time < _activeUntil ||
        _particles.isNotEmpty ||
        (_blinkAt != null && _time - _blinkAt! < 0.2) ||
        (_hopAt != null && _time - _hopAt! < 0.6) ||
        _tricks.any((t) => _time < t.$2 + RobotTricks.length(t.$1));
    _frame.value++;
    if (!busy) _ticker.stop();
  }

  void _trick(RobotTrick trick) {
    _tricks
      ..removeWhere((t) => _time > t.$2 + RobotTricks.length(t.$1))
      ..add((trick, _time));
  }

  Offset get _mouth => RobotMoves.mouth(_stage, centred: true);

  /// Plays [hello]: it waves, sends up hearts, gets stars or hearts for eyes, hops its hat, wiggles, spins, bounces or
  /// hums, smiling.
  void greet(RobotHello hello) {
    if (_reduced) return;
    _joyAt = _time;
    switch (hello) {
      case RobotHello.wave:
        _trick(RobotTrick.wave);
      case RobotHello.hearts:
        _hopAt = _time;
        _particles.addAll(RobotMoves.hearts(_mouth - const Offset(0, 0.2), _time));
      case RobotHello.starEyes:
        _joyAt = null;
        _trick(RobotTrick.starEyes);
        _particles.addAll(RobotMoves.sparkles(4, _mouth - const Offset(0, 0.12), _time, _random));
      case RobotHello.hatHop:
        _trick(RobotTrick.fezHop);
      case RobotHello.wiggle:
        _trick(RobotTrick.wiggle);
      case RobotHello.twirl:
        _trick(RobotTrick.twirl);
      case RobotHello.bounce:
        _trick(RobotTrick.bounce);
      case RobotHello.heartEyes:
        _trick(RobotTrick.heartEyes);
        _particles.addAll(RobotMoves.hearts(_mouth - const Offset(0, 0.2), _time));
      case RobotHello.hum:
        _joyAt = null;
        _trick(RobotTrick.hum);
        _particles.addAll(RobotMoves.notes(_mouth, _time - 0.1, _random));
    }
    _wake();
  }

  /// A pet: one of eight turns at random, as on the pocket model's sheet; three in a row send its hat flying.
  void pet() {
    HapticFeedback.selectionClick();
    _pets
      ..removeWhere((at) => _time - at > 1.5)
      ..add(_time);
    _joyAt = _time;
    if (_reduced) {
      _wake();
      return;
    }
    if (_pets.length >= 3) {
      _pets.clear();
      _hopAt = _time;
      _joyAt = null;
      _trick(RobotTrick.fezFly);
      _wake();
      return;
    }
    switch (_random.nextInt(8)) {
      case 0:
        _hopAt = _time;
        _particles.addAll(RobotMoves.hearts(_mouth - const Offset(0, 0.2), _time));
      case 1:
        _trick(RobotTrick.wiggle);
      case 2:
        _trick(RobotTrick.fezHop);
      case 3:
        _joyAt = null;
        _trick(RobotTrick.starEyes);
        _particles.addAll(RobotMoves.sparkles(4, _mouth - const Offset(0, 0.12), _time, _random));
      case 4:
        _trick(_outfit.hat.tassel ? RobotTrick.tasselSpin : RobotTrick.wiggle);
      case 5:
        _trick(RobotTrick.twirl);
      case 6:
        _trick(RobotTrick.bounce);
      default:
        _trick(RobotTrick.heartEyes);
        _particles.addAll(RobotMoves.hearts(_mouth - const Offset(0, 0.2), _time));
    }
    _wake();
  }

  (RobotTrick, double)? get _activeTrick {
    (RobotTrick, double)? showing;
    for (final t in _tricks) {
      if (_time >= t.$2 && _time < t.$2 + RobotTricks.length(t.$1) && (showing == null || t.$2 >= showing.$2)) {
        showing = t;
      }
    }
    return showing;
  }

  RobotFrame _frameOf(double temperature) {
    final blink = _blinkAt == null ? 0.0 : (1 - ((_time - _blinkAt!) / 0.1 - 1).abs()).clamp(0.0, 1.0);
    final hop = _hopAt == null ? 0.0 : math.sin(((_time - _hopAt!) / 0.5).clamp(0.0, 1.0) * math.pi);
    final joy = _joyAt != null && _time >= _joyAt! && _time - _joyAt! < 1.8;
    final trick = _activeTrick;
    return RobotFrame(
      time: _time,
      face: joy ? RobotFace.happy : RobotFace.calm,
      look: Offset.zero,
      blink: blink,
      hop: _reduced ? 0 : hop,
      temperature: temperature,
      level: _level,
      particles: List.unmodifiable(_particles),
      alive: !_reduced && _time < _activeUntil,
      mirrored: false,
      trick: trick?.$1,
      trickTime: trick == null ? 0 : _time - trick.$2,
      outfit: _outfit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PocketModelBloc?>()?.state;
    final (level, temperature) = switch (model) {
      PocketModelReady(:final model, :final temperature) => (model.level, temperature),
      _ => (context.watch<RobotLevelCubit?>()?.state ?? 0, 0.8),
    };
    _level = level;
    _outfit = widget.outfit ?? (context.watch<RobotOutfitCubit?>()?.state ?? RobotOutfit.initial).within(level);
    return LayoutBuilder(
      builder: (context, constraints) {
        _stage = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            if (PocketRobotPainter.hits(_stage, details.localPosition, centred: true, outfit: _outfit)) pet();
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: PocketRobotPainter(
              repaint: _frame,
              rug: widget.rug,
              centred: true,
              frame: () => _frameOf(temperature),
            ),
          ),
        );
      },
    );
  }
}
