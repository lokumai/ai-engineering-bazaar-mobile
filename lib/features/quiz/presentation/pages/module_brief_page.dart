import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart' hide Block;

import 'package:ai_engineering_bazaar/features/quiz/presentation/widgets/quiz_frame.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';

/// One card of a module in 2 minutes.
sealed class BriefCard {
  const BriefCard();
}

/// A point of the Summary: one of its paragraphs or lists.
final class SummaryCard extends BriefCard {
  const SummaryCard(this.block);

  final Block block;
}

/// A few of the Key Terms.
final class TermsCard extends BriefCard {
  const TermsCard(this.terms);

  final List<GlossaryTerm> terms;
}

/// The end: the way to the module's quiz.
final class EndCard extends BriefCard {
  const EndCard({required this.hasQuiz});

  final bool hasQuiz;
}

/// How many terms one card holds.
const _termsPerCard = 4;

/// The cards of [notes] (plan 13.7): the Summary point by point, then the Key Terms a few at a time, then the end.
/// Nothing new is written: every card is the module's own text.
List<BriefCard> briefCards(ModuleNotes notes) => [
  for (final block in notes.summary) SummaryCard(block),
  for (var i = 0; i < notes.terms.length; i += _termsPerCard)
    TermsCard(notes.terms.sublist(i, (i + _termsPerCard).clamp(0, notes.terms.length))),
  EndCard(hasQuiz: notes.quiz.isNotEmpty),
];

/// A module in 2 minutes full screen at `/practice/brief/<level>/<module>` (plan 13.7): swipe cards of the module's
/// Summary and Key Terms, then Take the quiz.
class ModuleBriefPage extends StatefulWidget {
  const ModuleBriefPage({super.key, required this.moduleKey});

  final String moduleKey;

  /// The key of the cards' pager.
  static const pagerKey = ValueKey('brief-pager');

  @override
  State<ModuleBriefPage> createState() => _ModuleBriefPageState();
}

class _ModuleBriefPageState extends State<ModuleBriefPage> {
  final _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _go(int page) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _pager.jumpToPage(page);
    } else {
      _pager.animateToPage(page, duration: BazaarMotion.fold, curve: BazaarMotion.bazaar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = context.watch<TrackCubit>().state;
    final language = context.watch<LanguageCubit>().state;
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      _ => null,
    };
    final title = index?.module(widget.moduleKey)?.tracks[track]?.titleIn(language) ?? S.of(context).practice_brief;
    final notes = switch (context.watch<StudyNotesCubit>().state) {
      final StudyNotesReady ready when ready.track == track && ready.language == language => ready.of(widget.moduleKey),
      _ => null,
    };
    return StudyNotesLoader(
      child: QuizFrame(
        title: title,
        child: notes == null ? const Center(child: CircularProgressIndicator()) : _cards(context, briefCards(notes)),
      ),
    );
  }

  Widget _cards(BuildContext context, List<BriefCard> cards) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final last = cards.length - 1;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: ModuleBriefPage.pagerKey,
            controller: _pager,
            itemCount: cards.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, page) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: _CardView(card: cards[page], moduleKey: widget.moduleKey),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Row(
            children: [
              IconButton(
                key: const Key('brief-previous'),
                tooltip: s.brief_previous,
                onPressed: _page == 0 ? null : () => _go(_page - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  s.brief_step(_page + 1, cards.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurface),
                ),
              ),
              IconButton(
                key: const Key('brief-next'),
                tooltip: s.brief_next,
                onPressed: _page == last ? null : () => _go(_page + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One card on a raised card, its content scrolling when it is longer than the screen.
class _CardView extends StatelessWidget {
  const _CardView({required this.card, required this.moduleKey});

  final BriefCard card;
  final String moduleKey;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final label = switch (card) {
      SummaryCard() => s.brief_summary,
      TermsCard() => s.brief_terms,
      EndCard() => null,
    };
    final body = TextStyle(fontSize: BazaarType.lead.size, height: 1.5, color: colors.onSurface);
    return BazaarCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            if (label != null) Text(label, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted)),
            ...switch (card) {
              SummaryCard(:final block) => [
                switch (block) {
                  ParagraphBlock(:final inlines) => InlineText(inlines: inlines, style: body, onLink: (_) {}),
                  _ => _BlockView(block: block),
                },
              ],
              TermsCard(:final terms) => [
                for (final term in terms)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(term.name, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle)),
                      InlineText(
                        inlines: term.definition,
                        style: TextStyle(fontSize: BazaarType.control.size, color: colors.onSurface),
                        onLink: (_) {},
                      ),
                    ],
                  ),
              ],
              EndCard(:final hasQuiz) => [
                Text(s.brief_end, style: body),
                if (hasQuiz)
                  FilledButton(
                    key: const Key('brief-take-quiz'),
                    onPressed: () => context.push(BazaarPaths.quiz(moduleKey)),
                    child: Text(s.brief_take_quiz),
                  ),
                OutlinedButton(
                  key: const Key('brief-open-module'),
                  onPressed: () => context.push(BazaarPaths.module(context.read<TrackCubit>().state, moduleKey)),
                  child: Text(s.brief_open_module),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

/// A Summary list, as the reader draws it.
class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});

  final Block block;

  @override
  Widget build(BuildContext context) {
    final themes = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index.diagramThemes,
      _ => null,
    };
    if (themes == null) return const SizedBox.shrink();
    return BlockList(
      blocks: [block],
      render: BlockRenderContext(onLink: (_) {}, webPage: null, headingKey: (_) => GlobalKey(), diagramThemes: themes),
    );
  }
}
