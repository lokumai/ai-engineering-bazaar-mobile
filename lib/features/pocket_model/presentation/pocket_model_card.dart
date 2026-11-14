import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_cubit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/outfit_names.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart' show cold;
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/tiny_lm.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/speech_bubble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/training_panel.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/finished_modules.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// The pocket model (plan 9.2, 9.4): a tiny model to play with when bored, in the sheet its button opens
/// (`pocket_assistant.dart`), over the app's [PocketModelBloc]. The reader feeds it tokens
/// and its language model reads them, a few words of its text at a time: its level rises, its loss on text it never
/// read falls, and what it writes goes from noise to the words it read to sentences of its own. Its temperature makes
/// it repeat itself when cold and hallucinate when hot; fed too fast it overfits; left for hours it grows hungry and
/// falls asleep. A tap pets it, and its eyes follow the finger.
///
/// It is drawn by one painter and moves only for a few seconds after the reader touches it; otherwise it only blinks
/// now and then, so the open sheet costs nothing while read. Under reduced motion nothing flies and nothing moves.
class PocketModelCard extends StatelessWidget {
  const PocketModelCard({super.key});

  @override
  Widget build(BuildContext context) => const _PocketModelView();
}

class _PocketModelView extends StatefulWidget {
  const _PocketModelView();

  @override
  State<_PocketModelView> createState() => _PocketModelViewState();
}

class _PocketModelViewState extends State<_PocketModelView> with SingleTickerProviderStateMixin {
  /// How long the robot stays lively after a touch.
  static const double _lively = 8;

  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final math.Random _random = math.Random();
  Timer? _blinker;

  double _time = 0;
  Duration _lastElapsed = Duration.zero;
  double _activeUntil = 0;
  double? _blinkAt;
  double? _hopAt;
  double? _eatAt;
  double? _joyAt;

  /// The tricks to play, each from its start on the stage's clock; the latest started one shows.
  final List<(RobotTrick, double)> _tricks = [];

  /// When it was last petted, to catch three pets in a row.
  final List<double> _pets = [];

  /// The words it knew at the last feed, to see a feed teach it new ones.
  int? _known;
  Timer? _glance;
  Offset _look = Offset.zero;
  Offset _lookTarget = Offset.zero;
  final List<Particle> _particles = [];
  Size _stage = Size.zero;

  /// What the robot wears at its level (plan 9.9).
  RobotOutfit _outfit = RobotOutfit.initial;

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  bool get _mirrored => Directionality.of(context) == TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    if (context.read<PocketModelBloc>().state case PocketModelReady(:final known)) _known = known;
    _scheduleBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<PocketModelBloc>().add(PocketModelLanguageSet(Localizations.localeOf(context).languageCode));
  }

  @override
  void dispose() {
    _blinker?.cancel();
    _glance?.cancel();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  // ---- the clock ------------------------------------------------------------------------------------------------

  void _scheduleBlink() {
    _blinker?.cancel();
    _blinker = Timer(Duration(milliseconds: 3200 + _random.nextInt(2600)), () {
      if (!mounted) return;
      final state = context.read<PocketModelBloc>().state;
      if (!_reduced && state is PocketModelReady && state.awake) {
        _blinkAt = _time;
        // Now and then, when nothing else is going on, it yawns or looks about.
        if (_activeTrick == null && _particles.isEmpty && _random.nextDouble() < 0.2) {
          _random.nextBool() ? _trick(RobotTrick.yawn) : _lookAbout();
        }
        _wake(lively: false);
      }
      _scheduleBlink();
    });
  }

  /// Starts the clock; [lively] keeps the robot breathing for a while.
  void _wake({bool lively = true}) {
    if (lively) _activeUntil = _time + _lively;
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
    _time += dt.clamp(0, 0.1);
    _look = Offset.lerp(_look, _lookTarget, 1 - math.exp(-dt * 8))!;
    _particles.removeWhere((p) => _time > p.born + p.life);
    final busy =
        _time < _activeUntil ||
        _particles.isNotEmpty ||
        (_blinkAt != null && _time - _blinkAt! < 0.2) ||
        (_hopAt != null && _time - _hopAt! < 0.6) ||
        _tricks.any((t) => _time < t.$2 + RobotTricks.length(t.$1)) ||
        (_look - _lookTarget).distance > 0.01;
    _frame.value++;
    if (!busy) _ticker.stop();
  }

  // ---- what the reader does ---------------------------------------------------------------------------------------

  void _onPointer(Offset local) {
    if (_stage == Size.zero) return;
    final seat = PocketRobotPainter.seat(_stage, mirrored: _mirrored);
    final s = PocketRobotPainter.scaleOf(_stage);
    final eyes = seat - Offset(0, 112 * s);
    final mirror = _mirrored ? -1.0 : 1.0;
    _lookTarget = Offset(
      ((local.dx - eyes.dx) / (_stage.width / 2) * mirror).clamp(-1, 1),
      ((local.dy - eyes.dy) / (_stage.height / 2)).clamp(-1, 1),
    );
    _wake();
  }

  void _onPointerEnd() {
    _lookTarget = Offset.zero;
    _wake();
  }

  void _onTap(TapUpDetails details) {
    if (PocketRobotPainter.hits(_stage, details.localPosition, mirrored: _mirrored, outfit: _outfit)) {
      context.read<PocketModelBloc>().add(const PocketModelPetted());
    }
  }

  /// Plays the model's latest action once: what flies, the hop, the face, the tick under the finger.
  void _play(PocketModelReady state) {
    final reduced = _reduced;
    final learnt = _known == null ? 0 : state.known - _known!;
    _known = state.known;
    switch (state.action) {
      case PocketAction.fed:
        HapticFeedback.lightImpact();
        _eatAt = _time;
        if (!reduced) _eat(state, learnt);
      case PocketAction.levelUp:
        HapticFeedback.mediumImpact();
        _eatAt = _time;
        _joyAt = _time + 0.6;
        _hopAt = _time + 0.6;
        if (!reduced) {
          _eat(state, learnt);
          _confetti();
        }
      case PocketAction.overfit || PocketAction.refused:
        HapticFeedback.heavyImpact();
        if (!reduced) _sparks();
      case PocketAction.petted:
        HapticFeedback.selectionClick();
        _joyAt = _time;
        // Two or three quick pets while it has spoken close its bubble.
        if (state.speech != null && _pets.where((at) => _time - at < 1.5).isNotEmpty) {
          context.read<PocketModelBloc>().add(const PocketModelHushed());
        }
        if (reduced) {
          _pets
            ..removeWhere((at) => _time - at > 1.5)
            ..add(_time);
        } else {
          _pet();
        }
      case PocketAction.woke:
        HapticFeedback.selectionClick();
        _joyAt = _time;
        _hopAt = _time;
      case PocketAction.recovered:
        _joyAt = _time;
      case PocketAction.studied:
        // A module read: a feast.
        HapticFeedback.mediumImpact();
        _eatAt = _time;
        _joyAt = _time + 0.9;
        if (!reduced) {
          _eat(state, learnt);
          _throwTokens(state.read.skip(5).toList(), swirl: true);
        }
      case PocketAction.spoke:
        if (!reduced) _speak(state);
      case PocketAction.none:
    }
    _wake();
  }

  /// The trick showing now: the latest started that has not ended.
  RobotTrick? get _activeTrick => _activeTrickAt?.$1;

  (RobotTrick, double)? get _activeTrickAt {
    (RobotTrick, double)? showing;
    for (final t in _tricks) {
      if (_time >= t.$2 && _time < t.$2 + RobotTricks.length(t.$1) && (showing == null || t.$2 >= showing.$2)) {
        showing = t;
      }
    }
    return showing;
  }

  void _trick(RobotTrick trick, {double after = 0}) {
    _tricks
      ..removeWhere((t) => _time > t.$2 + RobotTricks.length(t.$1))
      ..add((trick, _time + after));
  }

  /// A pet: one of five turns at random; three pets in a row send its fez flying.
  void _pet() {
    _pets
      ..removeWhere((at) => _time - at > 1.5)
      ..add(_time);
    if (_pets.length >= 3) {
      _pets.clear();
      _hopAt = _time;
      _joyAt = null;
      _trick(RobotTrick.fezFly);
      return;
    }
    switch (_random.nextInt(5)) {
      case 0:
        _hopAt = _time;
        _hearts();
      case 1:
        _trick(RobotTrick.wiggle);
      case 2:
        _trick(RobotTrick.fezHop);
      case 3:
        _joyAt = null;
        _trick(RobotTrick.starEyes);
        _sparkle(4, around: _mouth - const Offset(0, 0.12));
      default:
        // A hat with no tassel blushes instead.
        _trick(_outfit.hat.tassel ? RobotTrick.tasselSpin : RobotTrick.wiggle);
    }
  }

  /// A feed: the tokens arc or whirl in, it chews and drops crumbs, now and then burps, and new words sparkle.
  void _eat(PocketModelReady state, int learnt) {
    _throwTokens(state.read, swirl: _random.nextDouble() < 0.4);
    _crumbs();
    if (_random.nextDouble() < 0.2) _burp();
    if (learnt > 0) _sparkle(math.min(learnt, 5), around: _mouth - const Offset(0, 0.1), after: 0.6);
  }

  /// Asked: it thinks first; then, hot, its face flickers, and cold, its breath frosts.
  void _speak(PocketModelReady state) {
    _trick(RobotTrick.thinking);
    if (state.speech?.hallucinating ?? false) {
      _trick(RobotTrick.glitch, after: RobotTricks.length(RobotTrick.thinking));
    } else if (state.temperature < cold) {
      _frost(after: RobotTricks.length(RobotTrick.thinking));
    }
  }

  /// Looks to one side, then the other, then ahead again.
  void _lookAbout() {
    final side = _random.nextBool() ? 1.0 : -1.0;
    _lookTarget = Offset(side * 0.9, -0.2);
    _glance?.cancel();
    _glance = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _lookTarget = Offset(-side * 0.9, -0.1);
      _wake(lively: false);
      _glance = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _lookTarget = Offset.zero;
        _wake(lively: false);
      });
    });
  }

  String get _alphabet => switch (Localizations.localeOf(context).languageCode) {
    'fa' => 'توکنبپرس',
    _ => 'tokenabcdz',
  };

  /// Throws the first letters of the words it read into its mouth; letters at random when it read none.
  void _throwTokens(List<String> read, {bool swirl = false}) {
    const palette = [Color(0xffddb46a), Color(0xff63b2ab), Color(0xffc9c6e4), Color(0xffe6dac6), Color(0xffc9785f)];
    final mouth = _mouth;
    for (var i = 0; i < 5; i++) {
      _particles.add(
        Particle(
          kind: ParticleKind.token,
          born: _time + i * 0.07,
          life: 0.7,
          from: Offset(0.08 + _random.nextDouble() * 0.12, 0.98),
          to: mouth,
          label: i < read.length && read[i].isNotEmpty
              ? String.fromCharCode(read[i].runes.first)
              : _alphabet[_random.nextInt(_alphabet.length)],
          color: palette[i % palette.length],
          spin: swirl ? i * 2 * math.pi / 5 : (_random.nextDouble() - 0.5) * 6,
          swirl: swirl ? 0.22 : 0,
        ),
      );
    }
  }

  void _crumbs() {
    const palette = [Color(0xffddb46a), Color(0xffc8a078), Color(0xffe6dac6)];
    final mouth = _mouth + const Offset(0, 0.04);
    for (var i = 0; i < 6; i++) {
      _particles.add(
        Particle(
          kind: ParticleKind.crumb,
          born: _time + 0.75 + i * 0.05,
          life: 0.7,
          from: mouth,
          to: mouth + Offset((_random.nextDouble() - 0.5) * 0.14, 0.02),
          color: palette[i % palette.length],
        ),
      );
    }
  }

  void _burp() {
    final side = _mirrored ? 1.0 : -1.0;
    _particles.add(
      Particle(
        kind: ParticleKind.burp,
        born: _time + 1.1,
        life: 1.2,
        from: _mouth + Offset(side * 0.05, -0.02),
        to: _mouth + Offset(side * 0.12, -0.3),
        label: TinyLm.end,
      ),
    );
  }

  void _sparkle(int count, {required Offset around, double after = 0}) {
    for (var i = 0; i < count; i++) {
      final a = _random.nextDouble() * 2 * math.pi;
      final at = around + Offset(math.cos(a) * 0.1, math.sin(a) * 0.12);
      _particles.add(
        Particle(
          kind: ParticleKind.star,
          born: _time + after + i * 0.1,
          life: 0.8,
          from: at,
          to: at + const Offset(0, -0.05),
          color: const Color(0xffffd88a),
        ),
      );
    }
  }

  void _frost({double after = 0}) {
    final side = _mirrored ? 1.0 : -1.0;
    for (var i = 0; i < 4; i++) {
      _particles.add(
        Particle(
          kind: ParticleKind.frost,
          born: _time + after + i * 0.25,
          life: 1.2,
          from: _mouth + Offset(side * 0.02, 0),
          to: _mouth + Offset(side * (0.16 + i * 0.03), -0.06 - i * 0.02),
          color: const Color(0xffa9cdea),
        ),
      );
    }
  }

  Offset get _mouth {
    if (_stage == Size.zero) return const Offset(0.5, 0.5);
    final seat = PocketRobotPainter.seat(_stage, mirrored: _mirrored);
    final s = PocketRobotPainter.scaleOf(_stage);
    final at = seat - Offset(0, 96 * s);
    return Offset(at.dx / _stage.width, at.dy / _stage.height);
  }

  void _hearts() {
    final head = _mouth - const Offset(0, 0.2);
    for (var i = 0; i < 4; i++) {
      _particles.add(
        Particle(
          kind: ParticleKind.heart,
          born: _time + i * 0.12,
          life: 1.3,
          from: head + Offset((i - 1.5) * 0.06, 0),
          to: head + Offset((i - 1.5) * 0.1, -0.35),
          color: const Color(0xffe0607a),
          spin: i.toDouble(),
        ),
      );
    }
  }

  void _confetti() {
    const palette = [Color(0xffddb46a), Color(0xff2f8c86), Color(0xffb3262e), Color(0xff7a4a86), Color(0xff63b2ab)];
    final centre = _mouth - const Offset(0, 0.15);
    for (var i = 0; i < 22; i++) {
      final a = _random.nextDouble() * 2 * math.pi;
      final r = 0.2 + _random.nextDouble() * 0.25;
      _particles.add(
        Particle(
          kind: ParticleKind.confetti,
          born: _time + 0.55,
          life: 1.4,
          from: centre,
          to: centre + Offset(math.cos(a) * r, math.sin(a) * r * 0.7 - 0.15),
          color: palette[i % palette.length],
          spin: (_random.nextDouble() - 0.5) * 4,
        ),
      );
    }
  }

  void _sparks() {
    final centre = _mouth - const Offset(0, 0.12);
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * 2 * math.pi;
      _particles.add(
        Particle(
          kind: ParticleKind.spark,
          born: _time,
          life: 0.6,
          from: centre,
          to: centre + Offset(math.cos(a) * 0.2, math.sin(a) * 0.2),
          color: const Color(0xffe08ad6),
        ),
      );
    }
  }

  // ---- the picture ------------------------------------------------------------------------------------------------

  RobotFace _faceOf(PocketModelReady state, DateTime now) {
    if (!state.awake) return RobotFace.asleep;
    if (state.model.overfitAt(now)) return RobotFace.overfit;
    if (_eatAt != null && _time - _eatAt! < 0.9) return RobotFace.eating;
    if (_joyAt != null && _time - _joyAt! < 1.8 && _time >= _joyAt!) return RobotFace.happy;
    if (state.speech?.hallucinating ?? false) return RobotFace.hallucinating;
    if (state.temperature < cold) return RobotFace.cold;
    if (state.model.moodAt(now) == PocketMood.hungry) return RobotFace.hungry;
    return RobotFace.calm;
  }

  RobotFrame _frameOf(PocketModelReady state) {
    final blink = _blinkAt == null ? 0.0 : (1 - ((_time - _blinkAt!) / 0.1 - 1).abs()).clamp(0.0, 1.0);
    final hop = _hopAt == null ? 0.0 : math.sin(((_time - _hopAt!) / 0.5).clamp(0.0, 1.0) * math.pi);
    return RobotFrame(
      time: _time,
      face: _faceOf(state, clock.now()),
      look: _look,
      blink: blink,
      hop: _reduced ? 0 : hop,
      temperature: state.temperature,
      level: state.model.level,
      particles: List.unmodifiable(_particles),
      alive: !_reduced && _time < _activeUntil,
      mirrored: _mirrored,
      trick: _activeTrickAt?.$1,
      trickTime: _activeTrickAt == null ? 0 : _time - _activeTrickAt!.$2,
      outfit: _outfit,
    );
  }

  /// The line under its training, or null when there is nothing to say: content, it says nothing.
  String? _status(S s, PocketModelReady state, DateTime now) {
    if (!state.awake) return s.pocket_status_asleep;
    if (state.model.overfitAt(now)) return s.pocket_status_overfit;
    switch (state.action) {
      case PocketAction.recovered:
        return s.pocket_status_recovered;
      case PocketAction.levelUp:
        final unlocked = RobotOutfit.unlockedAt(state.model.level);
        if (unlocked.isNotEmpty) {
          return s.pocket_status_unlocked(state.model.level, unlocked.map((part) => outfitName(s, part)).join(', '));
        }
        return s.pocket_status_level_up(state.model.level);
      default:
    }
    if (state.speech?.hallucinating ?? false) return s.pocket_status_hallucinating;
    if (state.temperature < cold && state.speech != null) return s.pocket_status_cold;
    return switch (state.model.moodAt(now)) {
      PocketMood.newborn => s.pocket_status_newborn,
      PocketMood.hungry => s.pocket_status_hungry,
      PocketMood.asleep || PocketMood.content => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    return BlocConsumer<PocketModelBloc, PocketModelState>(
      listenWhen: (before, after) =>
          after is PocketModelReady && (before is! PocketModelReady || before.beat != after.beat),
      listener: (context, state) => _play(state as PocketModelReady),
      builder: (context, state) {
        final ready = switch (state) {
          PocketModelReady() => state,
          PocketModelLoading() => null,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionRule(title: s.pocket_title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.pocket_lede,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            if (ready == null)
              const SizedBox(height: 380)
            else
              BazaarCard(padding: EdgeInsets.zero, child: _content(context, ready)),
          ],
        );
      },
    );
  }

  Widget _content(BuildContext context, PocketModelReady state) {
    _outfit = context.watch<RobotOutfitCubit>().state.within(state.model.level);
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final now = clock.now();
    final model = state.model;
    final bloc = context.read<PocketModelBloc>();
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(
            height: 230,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.surfaceSunken, colors.surfaceRaised],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _stage = constraints.biggest;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Semantics(
                          container: true,
                          button: true,
                          label: s.pocket_stage_label(model.level),
                          onTap: () => bloc.add(const PocketModelPetted()),
                          excludeSemantics: true,
                          child: Listener(
                            onPointerDown: (event) => _onPointer(event.localPosition),
                            onPointerMove: (event) => _onPointer(event.localPosition),
                            onPointerHover: (event) => _onPointer(event.localPosition),
                            onPointerUp: (_) => _onPointerEnd(),
                            onPointerCancel: (_) => _onPointerEnd(),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: _onTap,
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: PocketRobotPainter(frame: () => _frameOf(state), repaint: _frame),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (state.speech case final speech? when state.awake)
                        PositionedDirectional(
                          top: 14,
                          start: 12,
                          width: _stage.width * 0.56,
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: SpeechBubble(
                              // A new answer is a new bubble; a pet or a feed beside it leaves it as it is.
                              key: ObjectKey(speech.tokens),
                              speech: speech,
                              // It thinks first when asked; overfit, it blurts.
                              delay: state.action == PocketAction.spoke && !_reduced
                                  ? Duration(milliseconds: (RobotTricks.length(RobotTrick.thinking) * 1000).round())
                                  : Duration.zero,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TrainingPanel(model: model, curve: state.curve, known: state.known),
              const SizedBox(height: AppSpacing.md),
              if (_status(s, state, now) case final status?) ...[
                AnimatedSwitcher(
                  duration: _reduced ? Duration.zero : const Duration(milliseconds: 220),
                  child: Semantics(
                    key: ValueKey(status),
                    liveRegion: true,
                    child: Text(status, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                spacing: AppSpacing.sm,
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('pocket-feed'),
                      onPressed: () => bloc.add(const PocketModelFed()),
                      icon: const Icon(Icons.scatter_plot_outlined),
                      label: Text(s.pocket_feed, maxLines: 1),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('pocket-ask'),
                      onPressed: () => bloc.add(const PocketModelAsked()),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(s.pocket_ask, maxLines: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReadModule(model: model),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(s.pocket_temperature, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
                  const Spacer(),
                  // The bead's colour in a dot beside the value, which is set in the text's colour to be read.
                  DecoratedBox(
                    decoration: BoxDecoration(color: beadColour(state.temperature), shape: BoxShape.circle),
                    child: const SizedBox.square(dimension: 10),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    NumberFormat('0.0', language).format(state.temperature),
                    style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurface),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.ac_unit, size: 20, color: beadColour(0)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: beadColour(state.temperature),
                        thumbColor: beadColour(state.temperature),
                      ),
                      child: Slider(
                        key: const ValueKey('pocket-temperature'),
                        value: state.temperature,
                        max: 2,
                        divisions: 20,
                        semanticFormatterCallback: (value) =>
                            '${s.pocket_temperature} ${NumberFormat('0.0', language).format(value)}',
                        onChanged: (value) {
                          bloc.add(PocketModelTemperatureSet(value));
                          _wake();
                        },
                      ),
                    ),
                  ),
                  Icon(Icons.local_fire_department_outlined, size: 20, color: beadColour(2)),
                ],
              ),
              // A model that read only modules can start over too.
              if (model.total > 0)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const ValueKey('pocket-reset'),
                    onPressed: () async {
                      if (await _askToStartOver(context)) bloc.add(const PocketModelReset());
                    },
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: Text(s.pocket_reset),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Asks before the model starts over; true for Start over, false when the dialog closes any other way.
Future<bool> _askToStartOver(BuildContext context) async {
  final reset = await showDialog<bool>(
    context: context,
    builder: (context) {
      final s = S.of(context);
      return AlertDialog(
        scrollable: true,
        title: Text(s.pocket_reset_title),
        content: Text(s.pocket_reset_body),
        actions: [
          TextButton(
            key: const ValueKey('pocket-reset-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.pocket_reset),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.pocket_reset_keep)),
        ],
      );
    },
  );
  return reset ?? false;
}

/// The modules the reader finished in the track they read that [model] has not read, from the course and the record;
/// none until both are ready.
List<String> finishedFor(BuildContext context, PocketModel model) {
  final content = context.watch<ContentBloc>().state;
  final record = context.watch<RecordBloc>().state;
  final track = context.watch<TrackCubit>().state;
  if (content is! ContentReady || record is! RecordReady) return const [];
  return finishedUnread(index: content.index, record: record.record, track: track, model: model);
}

/// The way to give it a module the reader finished (plan 9.6): the next by number, and how many wait; or a line saying
/// a finished module can be read.
class _ReadModule extends StatelessWidget {
  const _ReadModule({required this.model});

  final PocketModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final waiting = finishedFor(context, model);
    if (waiting.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          s.pocket_read_none,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey('pocket-read'),
          onPressed: () => context.read<PocketModelBloc>().add(PocketModelModuleRead(waiting.first)),
          icon: const Icon(Icons.auto_stories_outlined),
          label: Text(s.pocket_read_module, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 4),
        Text(
          s.pocket_read_waiting(waiting.length),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}
