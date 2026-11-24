import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/shared/study/domain/glossary.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/floating_room.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';

/// The glossary at `/practice/glossary` (plan 13.8): every Key Terms entry of the reader's track and language, A to Z,
/// with a field to find one. A term opens its definition and the modules that hold it; opening it counts as looking it
/// up, so it comes up in Today's review.
class GlossaryPage extends StatelessWidget {
  const GlossaryPage({super.key});

  /// The key of the entry whose first term has [termKey].
  static Key entryKey(String termKey) => ValueKey('glossary-$termKey');

  /// The key of the field that finds a term.
  static const findKey = ValueKey('glossary-find');

  @override
  Widget build(BuildContext context) {
    // The shell's Scaffold already makes room for the keyboard; this one making room again under it slid a second
    // ground up over the terms (the owner, 2026-11-18).
    return StudyNotesLoader(child: const Scaffold(resizeToAvoidBottomInset: false, body: _Glossary()));
  }
}

class _Glossary extends StatefulWidget {
  const _Glossary();

  @override
  State<_Glossary> createState() => _GlossaryState();
}

class _GlossaryState extends State<_Glossary> {
  final _find = TextEditingController();
  String _query = '';

  /// The open entries, by their first term's key.
  final _open = <String>{};

  @override
  void dispose() {
    _find.dispose();
    super.dispose();
  }

  void _clear() {
    _find.clear();
    setState(() => _query = '');
  }

  void _toggle(String key) {
    setState(() {
      if (!_open.remove(key)) {
        _open.add(key);
        context.read<ReviewBloc>().add(ReviewTermLookedUp(key));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final notes = switch (context.watch<StudyNotesCubit>().state) {
      final StudyNotesReady ready when ready.track == track && ready.language == language => ready,
      _ => null,
    };
    final entries = notes == null ? null : glossaryOf(notes.modules, language);
    final shown = entries == null ? null : glossaryFind(entries, _query, language);
    // The page's name and the field stay at the top; only the terms scroll under them, so the field never takes the
    // page up with it (the owner, 2026-11-18).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionRule(title: s.practice_glossary),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: GlossaryPage.findKey,
                controller: _find,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: false,
                // As the catalog's field: a tap elsewhere puts the keyboard away, since iOS has no back key to do it.
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: s.glossary_find,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: s.glossary_find_clear,
                          onPressed: _clear,
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  // 48 high, the least a tap target may be.
                  constraints: const BoxConstraints(minHeight: 48),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding:
                const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg) +
                EdgeInsets.only(bottom: FloatingRoom.of(context)),
            children: [
              if (shown == null)
                Center(child: CircularProgressIndicator(semanticsLabel: S.of(context).loading))
              else if (entries!.isEmpty)
                Text(s.practice_glossary_count(0), style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface))
              else if (shown.isEmpty)
                Text(s.glossary_none, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface))
              else
                // A to Z by letter; what a search finds, the best first, in one card.
                for (final (letter, group) in _query.trim().isEmpty ? _byLetter(shown, language) : [('', shown)]) ...[
                  if (letter.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SectionRule(title: letter),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  BazaarCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, entry) in group.indexed) ...[
                          if (i > 0) Divider(height: 1, color: colors.line),
                          _EntryView(
                            key: GlossaryPage.entryKey(entry.keyIn(track)),
                            entry: entry,
                            open: _open.contains(entry.keyIn(track)),
                            onToggle: () => _toggle(entry.keyIn(track)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

/// [entries], in their order, by the first letter of their names.
List<(String, List<GlossaryEntry>)> _byLetter(List<GlossaryEntry> entries, String language) {
  final groups = <(String, List<GlossaryEntry>)>[];
  for (final entry in entries) {
    final letter = glossaryLetter(entry.name, language);
    if (groups.lastOrNull case (final last, final group) when last == letter) {
      group.add(entry);
    } else {
      groups.add((letter, [entry]));
    }
  }
  return groups;
}

/// One entry: its name, and when open its definition on the sunken ground and the modules that hold it, each a small
/// label after its level's key.
class _EntryView extends StatelessWidget {
  const _EntryView({super.key, required this.entry, required this.open, required this.onToggle});

  final GlossaryEntry entry;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };
    final notes = context.watch<StudyNotesCubit>().state;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : BazaarMotion.fold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minTapTarget(theme.platform)),
              child: Padding(
                // The wider gap before the term, mirrored in Persian (plan 19.6).
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: displayFace(theme.textTheme.titleMedium)?.copyWith(color: colors.onSurfaceTitle),
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: duration,
                      child: Icon(Icons.expand_more, color: colors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: BazaarMotion.bazaar,
          alignment: Alignment.topCenter,
          child: !open
              ? const SizedBox(width: double.infinity)
              : Container(
                  color: colors.surfaceSunken,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.md,
                    children: [
                      InlineText(
                        inlines: entry.first.definition,
                        style: TextStyle(fontSize: BazaarType.control.size, height: 1.45, color: colors.onSurface),
                        onLink: (_) {},
                      ),
                      // Muted text on the sunken ground is 4.2:1 in the light look (review 7, finding 10).
                      Text(s.glossary_in, style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurface)),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final term in entry.terms)
                            if (index?.module(term.moduleKey) case final module?)
                              _ModuleLabel(
                                number: module.number,
                                title: module.tracks[track]?.titleIn(language) ?? term.moduleKey,
                                hue: levelHue(
                                  context,
                                  index!.levels.indexWhere((level) => level.slug == module.level).clamp(0, 99),
                                ),
                                onTap: () => context.push(
                                  BazaarPaths.module(track, term.moduleKey),
                                  extra: ReaderTarget(
                                    fragment: switch (notes) {
                                      StudyNotesReady() => notes.of(term.moduleKey)?.termsHeading,
                                      _ => null,
                                    },
                                    glance: true,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// A module that holds a term: its level's key, number and title on a small raised label; a tap opens the module at
/// its Key Terms.
class _ModuleLabel extends StatelessWidget {
  const _ModuleLabel({required this.number, required this.title, required this.hue, required this.onTap});

  final int number;
  final String title;
  final Color hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    // The tap is the node's own: excludeSemantics drops the InkWell's (review 8, finding 4).
    return Semantics(
      link: true,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(BazaarRadii.md),
          side: BorderSide(color: colors.lineStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minTapTarget(theme.platform)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  LevelKey(color: hue, size: 8),
                  Text(
                    number.toString().padLeft(2, '0'),
                    style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                  ),
                  Flexible(
                    child: Text(title, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceTitle)),
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
