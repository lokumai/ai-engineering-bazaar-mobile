import 'dart:async';
import 'dart:math' as math;

import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_bloc.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/babble.dart' show cold;
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/speech_bubble.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/widgets/training_panel.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Home's pocket model (plan 9.2): a tiny model to play with when bored, under Your path. The reader feeds it tokens
/// and it trains: its level rises, its loss falls, and what it says goes from letters to words to phrases. Its
/// temperature makes it repeat itself when cold and hallucinate when hot; fed too fast it overfits; left for hours it
/// grows hungry and falls asleep. A tap pets it, and its eyes follow the finger.
///
/// It is drawn by one painter and moves only for a few seconds after the reader touches it; otherwise it only blinks
/// now and then, so Home costs nothing while read. Under reduced motion nothing flies and nothing moves.
class PocketModelCard extends StatelessWidget {
  const PocketModelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PocketModelBloc(store: context.read<IPocketModelStore>())..add(const PocketModelStarted()),
      child: const _PocketModelView(),
    );
  }
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
  Offset _look = Offset.zero;
  Offset _lookTarget = Offset.zero;
  final List<Particle> _particles = [];
  Size _stage = Size.zero;

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  bool get _mirrored => Directionality.of(context) == TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<PocketModelBloc>().language = Localizations.localeOf(context).languageCode;
  }

  @override
  void dispose() {
    _blinker?.cancel();
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
        (_hopAt != null && _time - _hopAt! < 0.6);
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
    if (PocketRobotPainter.hits(_stage, details.localPosition, mirrored: _mirrored)) {
      context.read<PocketModelBloc>().add(const PocketModelPetted());
    }
  }

  /// Plays the model's latest action once: what flies, the hop, the face, the tick under the finger.
  void _play(PocketModelReady state) {
    final reduced = _reduced;
    switch (state.action) {
      case PocketAction.fed:
        HapticFeedback.lightImpact();
        _eatAt = _time;
        if (!reduced) _throwTokens();
      case PocketAction.levelUp:
        HapticFeedback.mediumImpact();
        _eatAt = _time;
        _joyAt = _time + 0.6;
        _hopAt = _time + 0.6;
        if (!reduced) {
          _throwTokens();
          _confetti();
        }
      case PocketAction.overfit || PocketAction.refused:
        HapticFeedback.heavyImpact();
        if (!reduced) _sparks();
      case PocketAction.petted:
        HapticFeedback.selectionClick();
        _joyAt = _time;
        _hopAt = _time;
        if (!reduced) _hearts();
      case PocketAction.woke:
        HapticFeedback.selectionClick();
        _joyAt = _time;
        _hopAt = _time;
      case PocketAction.recovered:
        _joyAt = _time;
      case PocketAction.spoke || PocketAction.none:
    }
    _wake();
  }

  String get _alphabet => switch (Localizations.localeOf(context).languageCode) {
    'fa' => 'توکنبپرس',
    _ => 'tokenabcdz',
  };

  void _throwTokens() {
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
          label: _alphabet[_random.nextInt(_alphabet.length)],
          color: palette[i % palette.length],
          spin: (_random.nextDouble() - 0.5) * 6,
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
    );
  }

  String _status(S s, PocketModelReady state, DateTime now) {
    if (!state.awake) return s.pocket_status_asleep;
    if (state.model.overfitAt(now)) return s.pocket_status_overfit;
    switch (state.action) {
      case PocketAction.recovered:
        return s.pocket_status_recovered;
      case PocketAction.levelUp:
        return s.pocket_status_level_up(state.model.level);
      default:
    }
    if (state.speech?.hallucinating ?? false) return s.pocket_status_hallucinating;
    if (state.temperature < cold && state.speech != null) return s.pocket_status_cold;
    return switch (state.model.moodAt(now)) {
      PocketMood.newborn => s.pocket_status_newborn,
      PocketMood.hungry => s.pocket_status_hungry,
      PocketMood.asleep || PocketMood.content => s.pocket_status_content,
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
            Text(s.pocket_lede, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted)),
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
                          width: _stage.width * 0.5,
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: SpeechBubble(key: ValueKey(state.beat), speech: speech),
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
              TrainingPanel(model: model),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: _reduced ? Duration.zero : const Duration(milliseconds: 220),
                child: Semantics(
                  key: ValueKey(_status(s, state, now)),
                  liveRegion: true,
                  child: Text(
                    _status(s, state, now),
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
              Row(
                children: [
                  Text(s.pocket_temperature, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
                  const Spacer(),
                  Text(
                    NumberFormat('0.0', language).format(state.temperature),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: beadColour(state.temperature).withValues(alpha: 1),
                    ),
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
            ],
          ),
        ),
      ],
    );
  }
}
