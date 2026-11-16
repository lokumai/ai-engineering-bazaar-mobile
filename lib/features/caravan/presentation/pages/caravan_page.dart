import 'package:ai_engineering_bazaar/features/caravan/application/caravan_cubit.dart';
import 'package:ai_engineering_bazaar/features/caravan/application/caravan_modules.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/sample_trends.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/caravan_journey.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/caravan_stage.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_stage.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/caravan_period.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/caravan_strip.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/trend_card.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/trend_list_sheet.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/reduced_motion.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Caravan tab at `/caravan` (plan 3.1, 9.1): what was trending in AI engineering, month by month since the chatbot
/// moment, as the web's shadow play (web M91, D116, C4), made for a phone (the owner, 2026-11-14: "inspired by the web,
/// not the same design; a phone cannot have the web's scroll").
///
/// From the top: the page's name and the notice that the trends are a sample; the stage, where the caravan walks the
/// road and stands at the chosen trend's stall; the strip of the whole road; the stop's buttons (previous, next, a tour
/// that walks the road on its own, and every trend in a sheet); and the chosen trend's card, which a swipe turns to
/// the next or the previous stop. Every way of moving chooses a stop in [CaravanCubit], and the caravan walks there.
///
/// The trends are the web's sample until the bundle carries the author's (`SampleCaravan`); the road is drawn from
/// them in the app's language.
class CaravanPage extends StatefulWidget {
  const CaravanPage({super.key});

  /// The stage's height on a phone of [screen] height.
  static double stageHeight(double screen) => (screen * 0.36).clamp(260, 330);

  @override
  State<CaravanPage> createState() => _CaravanPageState();
}

class _CaravanPageState extends State<CaravanPage> {
  final CaravanJourney _journey = CaravanJourney();
  late CaravanCubit _cubit;

  /// Whether the reader has moved the caravan on this visit; the hint shows until they do.
  bool _moved = false;

  /// The way the last move went, for the card's slide: 1 on, -1 back.
  int _direction = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<CaravanCubit>();
    _lastSelected ??= _cubit.state.selected;
  }

  CaravanRoad? _road;
  String? _roadLanguage;

  /// The road of the sample in [language], drawn once per language.
  CaravanRoad _roadIn(String language) {
    if (_road == null || _roadLanguage != language) {
      _road = SampleCaravan.road(language);
      _roadLanguage = language;
    }
    return _road!;
  }

  @override
  void dispose() {
    // A tour ends when the page closes, so the caravan is where the reader left it.
    _cubit.rest();
    _journey.dispose();
    super.dispose();
  }

  void _select(int index, int count) {
    _moved = true;
    _cubit.select(index, count: count);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final language = Localizations.localeOf(context).languageCode;
    final road = _roadIn(language);
    final count = road.stops.length;
    final track = context.watch<TrackCubit>().state;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };

    return BlocConsumer<CaravanCubit, CaravanState>(
      listenWhen: (before, after) => before.selected != after.selected,
      listener: (context, state) {
        HapticFeedback.selectionClick();
        setState(() => _direction = state.selected >= (_lastSelected ?? 0) ? 1 : -1);
        // A tour moves the caravan too; the hint has done its work once anything moves it.
        _moved = true;
        _lastSelected = state.selected;
      },
      builder: (context, state) {
        final selected = state.selected.clamp(0, count - 1);
        final stop = road.stops[selected];
        final touring = state is CaravanTouring;
        final modules = index == null ? const <CaravanModule>[] : courseModules(stop.trend, index, track, language);
        return LayoutBuilder(
          builder: (context, constraints) {
            final stageSize = Size(
              constraints.maxWidth - 16,
              CaravanPage.stageHeight(MediaQuery.sizeOf(context).height),
            );
            final geometry = StageGeometry(stageSize, road);
            String titleAt(int i) => road.stops[i].trend.title;
            return ListView(
              key: const PageStorageKey('caravan'),
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxl),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: SectionRule(title: s.nav_caravan),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _Notice(text: s.caravan_sample_notice),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox.fromSize(
                      size: stageSize,
                      child: CaravanStage(
                        road: road,
                        journey: _journey,
                        selected: selected,
                        onSelect: (i) => _select(i, count),
                        semanticLabel: s.caravan_stage_label(stop.trend.title),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: CaravanStrip(
                    road: road,
                    journey: _journey,
                    selected: selected,
                    span: geometry.span,
                    focusOffset: (StageGeometry.focus - 0.5) * geometry.span,
                    onSelect: (i) => _select(i, count),
                    label: s.caravan_strip_label,
                    value: '${stop.trend.title}, ${caravanPeriod(context, stop)}',
                    increased: selected < count - 1 ? titleAt(selected + 1) : null,
                    decreased: selected > 0 ? titleAt(selected - 1) : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('caravan-previous'),
                        tooltip: s.caravan_previous,
                        onPressed: selected > 0 ? () => _select(selected - 1, count) : null,
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl ? Icons.chevron_right : Icons.chevron_left,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.caravan_stop_of(selected + 1, count),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('caravan-next'),
                        tooltip: s.caravan_next,
                        onPressed: selected < count - 1 ? () => _select(selected + 1, count) : null,
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          key: const ValueKey('caravan-tour'),
                          onPressed: () {
                            _moved = true;
                            touring ? _cubit.rest() : _cubit.tour(count: count);
                          },
                          icon: Icon(touring ? Icons.pause : Icons.play_arrow),
                          label: Text(touring ? s.caravan_tour_stop : s.caravan_tour, maxLines: 1),
                        ),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('caravan-all'),
                          onPressed: () async {
                            final chosen = await showTrendListSheet(context, road: road, selected: selected);
                            if (chosen != null) _select(chosen, count);
                          },
                          icon: const Icon(Icons.format_list_bulleted),
                          label: Text(s.caravan_all_trends, maxLines: 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AnimatedSwitcher(
                    duration: motionDuration(context, const Duration(milliseconds: 320)),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) =>
                        Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                    transitionBuilder: (child, animation) {
                      final incoming = child.key == ValueKey(stop.trend.id);
                      final rtl = Directionality.of(context) == TextDirection.rtl;
                      final from = (incoming ? 0.25 : -0.25) * _direction * (rtl ? -1 : 1);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(begin: Offset(from, 0), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: TrendCard(
                      key: ValueKey(stop.trend.id),
                      stop: stop,
                      modules: modules,
                      sample: true,
                      onOpenModule: (key) => context.push(BazaarPaths.module(track, key)),
                      onNext: () => _select(selected + 1, count),
                      onPrevious: () => _select(selected - 1, count),
                    ),
                  ),
                ),
                if (!_moved) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        Icon(Icons.swipe, size: 18, color: colors.onSurfaceMuted),
                        Flexible(
                          child: Text(
                            s.caravan_hint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  int? _lastSelected;
}

/// The note that the trends are a sample, as the web's notice over its page.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BazaarFixedColors.caution.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BazaarFixedColors.caution.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Icon(Icons.info_outline, size: 18, color: colors.onSurfaceMuted),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}
