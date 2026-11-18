import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_engineering_bazaar/features/quiz/application/glossary.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_row.dart';
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
    return StudyNotesLoader(child: const Scaffold(body: _Glossary()));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg) + EdgeInsets.only(bottom: FloatingRoom.of(context)),
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
            decoration: InputDecoration(
              hintText: s.glossary_find,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (shown == null)
            const Center(child: CircularProgressIndicator())
          else if (entries!.isEmpty)
            Text(s.practice_glossary_count(0), style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface))
          else if (shown.isEmpty)
            Text(s.glossary_none, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface))
          else
            BazaarRows(
              children: [
                for (final entry in shown)
                  _EntryView(
                    key: GlossaryPage.entryKey(entry.keyIn(track)),
                    entry: entry,
                    open: _open.contains(entry.keyIn(track)),
                    onToggle: () => _toggle(entry.keyIn(track)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One entry: its name, and when open its definition and the modules that hold it.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: open,
          child: BazaarRow(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(entry.name, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                ),
                Icon(open ? Icons.expand_less : Icons.expand_more, color: colors.onSurfaceMuted),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                InlineText(
                  inlines: entry.first.definition,
                  style: TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface),
                  onLink: (_) {},
                ),
                Text(s.glossary_in, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
                for (final term in entry.terms)
                  TextButton(
                    style: TextButton.styleFrom(alignment: AlignmentDirectional.centerStart),
                    onPressed: () => context.push(
                      BazaarPaths.module(track, term.moduleKey),
                      extra: ReaderTarget(
                        fragment: switch (notes) {
                          StudyNotesReady() => notes.of(term.moduleKey)?.termsHeading,
                          _ => null,
                        },
                        glance: true,
                      ),
                    ),
                    child: Text(index?.module(term.moduleKey)?.tracks[track]?.titleIn(language) ?? term.moduleKey),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
