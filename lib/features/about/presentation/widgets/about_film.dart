import 'dart:async';

import 'package:ai_engineering_bazaar/features/about/presentation/about_art.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/about_palette.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_arch.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_ground.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/widgets/about_reveal.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How the reader leaves the story before its end: Welcome skips it, Settings closes it.
enum AboutExit { skip, close }

/// The story of the Bazaar as a short film over the whole screen, apart from the rest of the app: the web's About page
/// (web D115, "Procession" on "Dusk to dawn") told one screen at a time instead of under the scroll.
///
/// The opening draws the gate and raises the story's title in it; then each section on its own ground, its scene
/// coming in, its number, its heading word by word and its paragraph line by line; then the motto at dawn, in the gate
/// again, underlined by hand, and [finishLabel], which calls [onFinished]. Each screen moves on by itself once it has
/// been read for a while, and a bar at the top shows where the film is. A tap on the far side goes on at once, a tap on
/// the near side goes back, and holding the screen pauses it. [exit] leaves at any time.
///
/// Under reduced motion each screen is drawn in place; under a screen reader nothing moves on by itself, and the two
/// sides of the screen are its Previous and Next buttons.
class AboutFilm extends StatefulWidget {
  const AboutFilm({
    super.key,
    required this.story,
    required this.onFinished,
    required this.exit,
    required this.finishLabel,
    this.note,
  });

  final StoryDoc story;
  final VoidCallback onFinished;
  final AboutExit exit;
  final String finishLabel;

  /// A line under the title, as that the story is in English when the app is not.
  final String? note;

  /// The button at the motto that ends the film.
  static const finishKey = Key('about-finish');

  /// The skip or close button at the top.
  static const exitKey = Key('about-exit');

  /// The near and far sides of the screen.
  static const previousKey = Key('about-previous');
  static const nextKey = Key('about-next');

  @override
  State<AboutFilm> createState() => _AboutFilmState();
}

/// One screen of the film: how long its pieces take to arrive, and how long it stays in all.
sealed class _Shot {
  const _Shot(this.reveal, this.length);

  final double reveal;
  final double length;
}

final class _Opening extends _Shot {
  const _Opening() : super(3.2, 4.6);
}

final class _Section extends _Shot {
  _Section(this.position, this.stall) : super(_reveal, _reveal + (_words(stall) * 0.07).clamp(3.0, 6.0));

  final int position;
  final StoryStall stall;

  static const _reveal = 2.6;

  static int _words(StoryStall stall) =>
      [stall.heading, ...stall.paragraphs].fold(0, (sum, text) => sum + text.split(RegExp(r'\s+')).length);
}

final class _Motto extends _Shot {
  const _Motto(this.motto) : super(3.6, 3.6);

  final StoryMotto motto;
}

class _AboutFilmState extends State<AboutFilm> with TickerProviderStateMixin {
  late final List<_Shot> _shots = [
    const _Opening(),
    for (final (position, stall) in widget.story.stalls.indexed) _Section(position, stall),
    if (widget.story.motto case final motto?) _Motto(motto),
  ];

  int _index = 0;
  late AnimationController _clock = _start(_shots.first);

  /// The clocks of screens that went, kept while their screen fades out and let go at the next screen; a clock that is
  /// let go stays stopped where it was, so a screen still fading reads it as it was.
  final List<AnimationController> _gone = [];

  /// The film holds while the app is out of sight.
  late final AppLifecycleListener _lifecycle;

  bool get _last => _index == _shots.length - 1;

  AnimationController _start(_Shot shot) {
    final clock = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (shot.length * 1000).round()),
    )..addStatusListener(_onStatus);
    return clock..forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _last || !mounted) return;
    if (MediaQuery.accessibleNavigationOf(context)) return;
    _go(_index + 1);
  }

  void _go(int index) {
    if (index < 0 || index >= _shots.length) return;
    final shot = _shots[index];
    if (shot is _Section && shot.position < AboutArt.scenes.length) {
      // A scene starts from its first frame each time its section comes in.
      unawaited(AssetImage(AboutArt.scenes[shot.position]).evict());
    }
    for (final clock in _gone) {
      clock.dispose();
    }
    _gone
      ..clear()
      ..add(_clock..stop());
    setState(() {
      _index = index;
      _clock = _start(shot);
    });
  }

  void _next() {
    if (_last) {
      // The motto's pieces all arrive at a tap; the film ends at its button.
      _clock.value = 1;
      return;
    }
    _go(_index + 1);
  }

  void _previous() => _index == 0 ? _go(0) : _go(_index - 1);

  void _onTapUp(TapUpDetails details, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final near = rtl ? details.localPosition.dx > width * 0.7 : details.localPosition.dx < width * 0.3;
    near ? _previous() : _next();
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: () => _clock.stop(), onShow: () => _clock.forward());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _clock.dispose();
    for (final clock in _gone) {
      clock.dispose();
    }
    _gone.clear();
    super.dispose();
  }

  Color _ground(_Shot shot) => switch (shot) {
    _Opening() => AboutPalette.groundOpening,
    _Section(:final position) => AboutPalette.ground(position),
    _Motto() => AboutPalette.groundDawn,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final media = MediaQuery.of(context);
    final still = media.disableAnimations || media.accessibleNavigation;
    final shot = _shots[_index];
    final dawn = shot is _Motto;
    final ink = dawn ? AboutPalette.dawnInk : AboutPalette.ink;
    final overlay = (dawn ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: _ground(shot),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Material(
        type: MaterialType.transparency,
        child: AboutGround(
          color: _ground(shot),
          dawn: dawn,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              // A screen reader has the Previous and Next sides below instead.
              excludeFromSemantics: true,
              onTapUp: (details) => _onTapUp(details, constraints.maxWidth),
              onLongPressStart: (_) => _clock.stop(),
              onLongPressEnd: (_) => _clock.forward(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The two sides as buttons for a screen reader; they take no touch of their own.
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Semantics(
                          key: AboutFilm.previousKey,
                          button: true,
                          label: s.about_previous,
                          onTap: _previous,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Semantics(
                          key: AboutFilm.nextKey,
                          button: true,
                          label: s.about_next,
                          onTap: _next,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: AnimatedSwitcher(
                        duration: still ? Duration.zero : const Duration(milliseconds: 500),
                        // The screen that goes is gone in the first half, so its words never lie over the next.
                        switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
                        switchInCurve: const Interval(0.3, 1, curve: Curves.easeOut),
                        child: KeyedSubtree(
                          key: ValueKey(_index),
                          child: _Screen(shot: shot, clock: _clock, still: still, film: widget),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: _Progress(count: _shots.length, index: _index, clock: _clock, dawn: dawn),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: switch (widget.exit) {
                              AboutExit.skip => TextButton(
                                key: AboutFilm.exitKey,
                                onPressed: widget.onFinished,
                                style: TextButton.styleFrom(foregroundColor: ink),
                                child: Text(s.about_skip),
                              ),
                              AboutExit.close => IconButton(
                                key: AboutFilm.exitKey,
                                onPressed: widget.onFinished,
                                color: ink,
                                tooltip: s.about_close,
                                icon: const Icon(Icons.close),
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One segment per screen: the screens gone are full, the current one fills with its clock.
class _Progress extends StatelessWidget {
  const _Progress({required this.count, required this.index, required this.clock, required this.dawn});

  final int count;
  final int index;
  final Animation<double> clock;
  final bool dawn;

  @override
  Widget build(BuildContext context) {
    final track = dawn ? AboutPalette.dawnLine : AboutPalette.line;
    final fill = dawn ? AboutPalette.dawnTitle : AboutPalette.title;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) => Row(
          spacing: 4,
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: i < index ? 1 : (i == index ? clock.value : 0),
                      backgroundColor: track,
                      color: fill,
                      minHeight: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The screen [shot] at its [clock].
class _Screen extends StatelessWidget {
  const _Screen({required this.shot, required this.clock, required this.still, required this.film});

  final _Shot shot;
  final Animation<double> clock;
  final bool still;
  final AboutFilm film;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: clock,
    builder: (context, _) {
      final at = RevealClock(clock.value * shot.length, still: still);
      return switch (shot) {
        _Opening() => _OpeningView(story: film.story, note: film.note, clock: at),
        _Section(:final position, :final stall) => _SectionView(position: position, stall: stall, clock: at),
        _Motto(:final motto) => _MottoView(
          motto: motto,
          clock: at,
          finishLabel: film.finishLabel,
          onFinished: film.onFinished,
        ),
      };
    },
  );
}

/// The gate draws itself and the story's title rises in it, its first word set apart in the opening's glaze.
class _OpeningView extends StatelessWidget {
  const _OpeningView({required this.story, required this.note, required this.clock});

  final StoryDoc story;
  final String? note;
  final RevealClock clock;

  @override
  Widget build(BuildContext context) {
    final words = (story.title ?? S.of(context).settings_story).split(' ');
    final lead = words.first;
    final rest = words.skip(1).join(' ');
    final big = AboutPalette.fraunces(
      size: 46,
      weight: 680,
      optical: 110,
      color: AboutPalette.title,
      height: 1.02,
      tracking: -0.018,
    );
    final small = AboutPalette.fraunces(
      size: 46 * 0.62,
      weight: 460,
      optical: 110,
      italic: true,
      color: AboutPalette.hueOpening,
      height: 1.1,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxHeight * 0.72).clamp(0.0, 560.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                height: height,
                width: height * ArchPainter.aspect,
                child: CustomPaint(
                  painter: ArchPainter(
                    outer: clock.at(0, 2.4, RevealCurves.draw),
                    inner: clock.at(0.29, 2.4, RevealCurves.draw),
                    finial: clock.at(1.92, 0.72, RevealCurves.pop),
                    color: AboutPalette.gold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: height * 0.16, left: 32, right: 32),
              child: Semantics(
                header: true,
                label: story.title ?? S.of(context).settings_story,
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Rise(
                        progress: clock.at(0.5, 1.5, RevealCurves.rise),
                        from: 1.15,
                        child: Text(lead, style: small),
                      ),
                      if (rest.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        RisingWords(
                          text: rest,
                          style: big,
                          clock: clock,
                          start: 0.6,
                          stagger: 0.1,
                          duration: 1.5,
                          from: 1.15,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (note case final note?) ...[
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: clock.at(2.2, 0.8),
                          child: Text(
                            note,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AboutPalette.muted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A section: its scene comes in, then its number, its heading word by word and its paragraphs line by line.
class _SectionView extends StatelessWidget {
  const _SectionView({required this.position, required this.stall, required this.clock});

  final int position;
  final StoryStall stall;
  final RevealClock clock;

  @override
  Widget build(BuildContext context) {
    final hue = AboutPalette.hue(position);
    final number = AboutPalette.fraunces(size: 22, weight: 500, italic: true, color: hue, height: 1);
    final heading = AboutPalette.fraunces(
      size: 24,
      weight: 600,
      color: AboutPalette.title,
      height: 1.2,
      tracking: -0.012,
    );
    final body = Theme.of(context).textTheme.bodyLarge!.copyWith(color: AboutPalette.ink, fontSize: 17, height: 1.6);
    final scene = clock.at(0, 1.3, RevealCurves.settle);
    final mark = clock.at(0.35, 0.8, RevealCurves.settle);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneHeight = (constraints.maxHeight * 0.42).clamp(0.0, constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (position < AboutArt.scenes.length)
              SizedBox(
                height: sceneHeight,
                child: Opacity(
                  opacity: scene,
                  child: Transform.scale(
                    scale: 0.94 + 0.06 * scene,
                    child: _Scene(position: position),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: mark,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - mark)),
                          child: Row(
                            spacing: 12,
                            children: [
                              Transform.rotate(
                                angle: 0.785398,
                                child: SizedBox.square(dimension: 11, child: ColoredBox(color: hue)),
                              ),
                              Text('${position + 1}', style: number),
                              SizedBox(width: 64, height: 1, child: ColoredBox(color: hue.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RisingWords(text: stall.heading, style: heading, clock: clock, start: 0.5, header: true),
                    for (final (i, paragraph) in stall.paragraphs.indexed) ...[
                      const SizedBox(height: 14),
                      RisingLines(text: paragraph, style: body, clock: clock, start: 0.9 + i * 0.5),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A scene with no box: its edges melt into the ground, as the web's scenes stand on the page with no frame. It is
/// decoration; the heading and the paragraphs carry the section. Under reduced motion `Image` holds its first frame.
class _Scene extends StatelessWidget {
  const _Scene({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: AspectRatio(
        aspectRatio: AboutArt.aspects[position],
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => ellipseGradient(
            rect.center,
            rect.width / 2,
            rect.height / 2,
            const [Color(0xffffffff), Color(0xffffffff), Color(0x00ffffff)],
            const [0, 0.62, 1],
          ),
          child: Image.asset(
            AboutArt.scenes[position],
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

/// The motto at dawn, in the gate again: its lead, its words rising, the hand's line under it, then the way out.
class _MottoView extends StatelessWidget {
  const _MottoView({required this.motto, required this.clock, required this.finishLabel, required this.onFinished});

  final StoryMotto motto;
  final RevealClock clock;
  final String finishLabel;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final lead = AboutPalette.fraunces(size: 20, weight: 500, italic: true, color: AboutPalette.dawnMuted);
    final first = AboutPalette.fraunces(
      size: 32,
      weight: 700,
      optical: 110,
      color: AboutPalette.dawnTitle,
      height: 1.08,
      tracking: -0.018,
    );
    final second = first.copyWith(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation.weight(480), FontVariation.opticalSize(110)],
      color: AboutPalette.hueDawn,
    );
    final firstLine = motto.lines.first;
    final rest = motto.lines.skip(1).join(' ');
    final button = clock.at(3.0, 0.6, RevealCurves.settle);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 32).clamp(0.0, 440.0);
        final archHeight = (width / ArchPainter.aspect).clamp(0.0, constraints.maxHeight * 0.78);
        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                // At a large text scale the motto may outgrow its gate, and scrolls.
                builder: (context, area) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: area.maxHeight),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ExcludeSemantics(
                          child: SizedBox(
                            height: archHeight,
                            width: archHeight * ArchPainter.aspect,
                            child: CustomPaint(
                              painter: ArchPainter(
                                outer: clock.at(0, 2, RevealCurves.draw),
                                inner: clock.at(0.24, 2, RevealCurves.draw),
                                color: AboutPalette.dawnGold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: archHeight * 0.16, left: 40, right: 40),
                          child: MergeSemantics(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: clock.at(0.4, 1),
                                  child: Text('${motto.lead}:', style: lead, textAlign: TextAlign.center),
                                ),
                                const SizedBox(height: 18),
                                RisingWords(
                                  text: firstLine,
                                  style: first,
                                  clock: clock,
                                  start: 0.6,
                                  stagger: 0.07,
                                  duration: 1.1,
                                  from: 1.15,
                                  textAlign: TextAlign.center,
                                ),
                                if (rest.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  RisingWords(
                                    text: rest,
                                    style: second,
                                    clock: clock,
                                    start: 0.6 + firstLine.split(' ').length * 0.07,
                                    stagger: 0.07,
                                    duration: 1.1,
                                    from: 1.15,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                ExcludeSemantics(
                                  child: SizedBox(
                                    width: (width * 0.7).clamp(0.0, 400.0),
                                    child: AspectRatio(
                                      aspectRatio: HandLinePainter.aspect,
                                      child: CustomPaint(
                                        painter: HandLinePainter(
                                          stroke: clock.at(1.4, 1.6, RevealCurves.draw),
                                          dot: clock.at(2.8, 0.5, RevealCurves.pop),
                                          color: AboutPalette.dawnGold,
                                          dotColor: AboutPalette.hueDawn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Opacity(
                opacity: button,
                child: IgnorePointer(
                  ignoring: button < 0.5,
                  child: FilledButton.icon(
                    key: AboutFilm.finishKey,
                    onPressed: onFinished,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AboutPalette.dawnTitle,
                      foregroundColor: AboutPalette.groundDawn,
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    iconAlignment: IconAlignment.end,
                    label: Text(finishLabel),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
