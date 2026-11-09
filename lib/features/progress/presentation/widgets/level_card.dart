import 'dart:math' as math;

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/selectors.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The no-reading form the web prints before the record is read (`ProgressTabs.tsx:10`).
const progressNoReading = '--';

/// A level's card on the progress page (web `CourseCompletion.tsx:149-277`): the heading (the 1-based position padded
/// to two digits, then the title), the [CompletionDial], and one [ModuleRow] per module of the level. The redesign
/// draws it as an arch card with the level's hue along its top and in its dial (plan Phase 1G).
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.position,
    required this.level,
    required this.track,
    required this.index,
    required this.facts,
    required this.count,
    required this.record,
  });

  /// The 0-based position of [level] in `index.levels`.
  final int position;
  final LevelEntry level;

  /// The panel's track: the record it reads and the track its links open.
  final Track track;
  final BundleIndex index;

  /// The level's modules in number order.
  final List<CurriculumFact> facts;

  /// The level's count in [track], null while the record loads.
  final LevelCount? count;

  /// Null while the record loads.
  final RecordData? record;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final count = this.count;
    final hue = levelHue(context, position);
    return BazaarCard(
      shape: BazaarCardShape.arch,
      accent: hue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  container: true,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        (position + 1).toString().padLeft(2, '0'),
                        style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceMuted),
                      ),
                      Text(level.title, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              CompletionDial(
                text: count == null
                    ? s.progress_level_dial(progressNoReading, level.total)
                    : s.progress_level_dial(count.approved.toString(), count.total),
                fraction: count == null || count.total == 0 ? 0 : count.approved / count.total,
                fill: hue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final fact in facts)
            ModuleRow(
              key: Key('progress_row_${fact.slug}'),
              fact: fact,
              // The For Engineers title in both tabs, as the web's (A34).
              title: index.module(fact.slug)!.tracks[Track.engineers]!.title,
              track: track,
              signed: record?.signedOff(fact.slug, track) != null,
            ),
        ],
      ),
    );
  }
}

/// The level's dial (web `completion.css:540-553`): a ring filled to the completed fraction with [text] inside. It is
/// hidden from assistive technology, as the web's (`aria-hidden`), since the rows carry each state.
class CompletionDial extends StatelessWidget {
  const CompletionDial({super.key, required this.text, required this.fraction, required this.fill});

  /// `{approved}/{total}`, or `--/{total}` while the record loads.
  final String text;

  /// From 0 to 1.
  final double fraction;

  /// The filled part of the ring: the level's hue.
  final Color fill;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _size,
        child: CustomPaint(
          painter: _DialPainter(fraction: fraction, track: colors.surfaceSunken, fill: fill),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.onSurface)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({required this.fraction, required this.track, required this.fill});

  final double fraction;
  final Color track;
  final Color fill;

  static const double _stroke = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawOval(rect, paint..color = track);
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction.clamp(0, 1), false, paint..color = fill);
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.track != track || oldDelegate.fill != fill;
}

/// One module of a level card (web `CourseCompletion.tsx:187-276`): a completion toggle when [fact] is written in
/// [track], a dashed ring that says `Planned` when it is not, then the link to the module in [track].
class ModuleRow extends StatelessWidget {
  const ModuleRow({super.key, required this.fact, required this.title, required this.track, required this.signed});

  final CurriculumFact fact;

  /// The For Engineers title (A34).
  final String title;
  final Track track;

  /// Whether [track]'s record holds a completion for this module.
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final minHeight = minTapTarget(theme.platform);
    final Widget leading;
    if (fact.drawn) {
      void toggle() => context.read<RecordBloc>().add(CompletionToggled(key: fact.slug, revision: null, track: track));
      // The name says which module and what a tap does; the checked state says whether it is complete.
      leading = Semantics(
        container: true,
        checked: signed,
        label: s.progress_complete_module(title),
        onTap: toggle,
        excludeSemantics: true,
        child: InkResponse(
          onTap: toggle,
          child: SizedBox.square(
            dimension: minHeight,
            child: Center(child: ProgressMark(signed ? ProgressMarkKind.complete : ProgressMarkKind.notYet)),
          ),
        ),
      );
    } else {
      // Absent, not disabled: no control, and the mark says why (web `CourseCompletion.tsx:244-247`).
      leading = Semantics(
        container: true,
        label: s.module_planned,
        child: SizedBox.square(
          dimension: minHeight,
          child: const Center(child: ProgressMark(ProgressMarkKind.planned)),
        ),
      );
    }
    return Row(
      children: [
        leading,
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: InkWell(
            onTap: () => context.push(BazaarPaths.module(track, fact.slug)),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  s.progress_module_link(fact.number.toString().padLeft(2, '0'), title),
                  // The web's faint ink fails the text contrast guideline, so a planned row reads muted.
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: fact.drawn ? colors.onSurface : colors.onSurfaceMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The three marks of a module row, which the legend teaches.
enum ProgressMarkKind { complete, notYet, planned }

/// A module row's mark (web `completion.css:699-719,757-764`): a filled success disc with a check, an empty ring, or a
/// dashed ring. A graphic only; the row's semantics carry the state.
class ProgressMark extends StatelessWidget {
  const ProgressMark(this.kind, {super.key});

  final ProgressMarkKind kind;

  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    return SizedBox.square(
      dimension: _size,
      child: CustomPaint(
        painter: _MarkPainter(
          kind: kind,
          fill: BazaarFixedColors.success,
          check: colors.onPrimary,
          ring: colors.onSurfaceMuted,
          dashed: colors.onSurfaceFaint,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.kind,
    required this.fill,
    required this.check,
    required this.ring,
    required this.dashed,
  });

  final ProgressMarkKind kind;
  final Color fill;
  final Color check;
  final Color ring;
  final Color dashed;

  static const double _stroke = 2;
  static const int _dashes = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    switch (kind) {
      case ProgressMarkKind.complete:
        canvas.drawOval(Offset.zero & size, Paint()..color = fill);
        final tick = Path()
          ..moveTo(size.width * 0.28, size.height * 0.52)
          ..lineTo(size.width * 0.44, size.height * 0.68)
          ..lineTo(size.width * 0.74, size.height * 0.36);
        canvas.drawPath(
          tick,
          stroke
            ..color = check
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case ProgressMarkKind.notYet:
        canvas.drawOval(rect, stroke..color = ring);
      case ProgressMarkKind.planned:
        // Half of each arc step is drawn, half left open.
        const step = 2 * math.pi / _dashes;
        for (var dash = 0; dash < _dashes; dash++) {
          canvas.drawArc(rect, dash * step, step / 2, false, stroke..color = dashed);
        }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.fill != fill ||
      oldDelegate.check != check ||
      oldDelegate.ring != ring ||
      oldDelegate.dashed != dashed;
}
