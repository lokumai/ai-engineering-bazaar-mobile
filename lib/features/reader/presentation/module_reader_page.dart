import 'dart:async';

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/completion_row.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/contents_drawer.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/not_written_view.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/objectives_card.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/pager.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/prerequisites_box.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/reader_footer.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/schedule_of_parts.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/status_band.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/link_actions.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/quiz_slot.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/reduced_motion.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The module [moduleKey] in [track] (spec 3.6.3): opens a [ModuleReaderBloc] over the content index in context and
/// shows [ModuleReaderView].
///
/// The app mounts the router only once the content is ready (spec 3.7), so any other content state is a fault. The
/// reader keeps the index it opened with (spec 3.4.4).
class ModuleReaderPage extends StatelessWidget {
  const ModuleReaderPage({super.key, required this.moduleKey, required this.track, this.fragment, this.quizBuilder});

  final String moduleKey;
  final Track track;

  /// The heading to scroll to once the module is drawn, from a link to a section of the module.
  final String? fragment;

  /// Draws the quiz of a module that has one; null draws none (Decision A38).
  final QuizBuilder? quizBuilder;

  @override
  Widget build(BuildContext context) {
    final index = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index,
      final state => throw StateError('The reader needs ready content, not $state'),
    };
    return BlocProvider(
      create: (context) => ModuleReaderBloc(
        repository: context.read<IContentRepository>(),
        index: index,
        recordBloc: context.read<RecordBloc>(),
      )..add(ReaderOpened(key: moduleKey, track: track)),
      child: ModuleReaderView(fragment: fragment, quizBuilder: quizBuilder),
    );
  }
}

/// The body of the reader, from the [ModuleReaderBloc] in context, in the web's order (`ModuleSheet.tsx:242-518`):
/// the contents button, the status band of a planned module, the title, the facts, the prerequisites, the objectives,
/// the body (or the summary, the schedule of parts and the written sections of a draft), the completion, the pager, the
/// quiz and the footer.
class ModuleReaderView extends StatefulWidget {
  const ModuleReaderView({super.key, this.fragment, this.quizBuilder});

  final String? fragment;
  final QuizBuilder? quizBuilder;

  @override
  State<ModuleReaderView> createState() => _ModuleReaderViewState();
}

class _ModuleReaderViewState extends State<ModuleReaderView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// The key of each heading of [_keyedDoc], by heading id.
  final _headingKeys = <String, GlobalKey>{};
  ModuleDoc? _keyedDoc;

  bool _fragmentScheduled = false;

  /// The heading chosen in the contents drawer, scrolled to once the drawer has closed.
  String? _drawerTarget;

  GlobalKey _headingKey(String id) => _headingKeys.putIfAbsent(id, GlobalKey.new);

  /// Scrolls the heading [id] to the top, at once under reduced motion (spec 3.10).
  void _scrollTo(String id) {
    final target = _headingKeys[id]?.currentContext;
    if (target == null) throw StateError('No heading of this module has the id $id');
    unawaited(Scrollable.ensureVisible(target, duration: motionDuration(context, BazaarMotion.shift)));
  }

  void _selectFromDrawer(String id) {
    _drawerTarget = id;
    _scaffoldKey.currentState!.closeEndDrawer();
  }

  void _onEndDrawerChanged(bool open) {
    final id = _drawerTarget;
    if (open || id == null) return;
    _drawerTarget = null;
    _scrollTo(id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModuleReaderBloc, ReaderState>(
      builder: (context, state) => switch (state) {
        ReaderLoading() => const Scaffold(body: Center(child: CircularProgressIndicator())),
        ReaderNotFound() => const Scaffold(body: NotFoundView()),
        ReaderFailed() => const Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: ContentUnreadable()),
        ),
        ReaderNotWritten(:final entry) => Scaffold(body: NotWrittenView(entry: entry)),
        ReaderWritten(:final doc, :final entry, :final moduleCount) => _module(context, doc, entry, moduleCount),
        ReaderPlanned(:final doc, :final entry, :final moduleCount) => _module(context, doc, entry, moduleCount),
      },
    );
  }

  Widget _module(BuildContext context, ModuleDoc doc, ModuleEntry entry, int moduleCount) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final draft = doc.draft;
    final body = doc.body;
    final written = body != null;
    if (doc != _keyedDoc) {
      _headingKeys.clear();
      _keyedDoc = doc;
    }
    _scheduleFragment();

    final diagramThemes = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index.diagramThemes,
      final state => throw StateError('The reader needs ready content, not $state'),
    };
    final render = BlockRenderContext(
      onLink: (target) => followLink(context, target, scrollTo: _scrollTo),
      // A37: the base URL and the web path are concatenated, never resolved (spec 3.4.7).
      webPage: context.read<WebLinks>().webPage(entry.tracks[doc.track]!.webPath),
      headingKey: _headingKey,
      diagramThemes: diagramThemes,
    );
    // The web gives a draft no contents rail (ModuleSheet.tsx:298-300) and lists depth 2 only.
    final sections = written
        ? [
            for (final entry in doc.toc)
              if (entry.depth == 2) entry,
          ]
        : const <TocEntry>[];
    final quiz = doc.quiz;
    final quizBuilder = widget.quizBuilder;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: sections.isEmpty ? null : ContentsDrawer(entries: sections, onSelect: _selectFromDrawer),
      onEndDrawerChanged: _onEndDrawerChanged,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sections.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
                  icon: const Icon(Icons.toc),
                  label: Text(s.reader_contents),
                ),
              ),
            if (draft != null && !written) ...[
              StatusBand(partlyWritten: draft.written != null),
              const SizedBox(height: 20),
            ],
            Semantics(header: true, child: Text(doc.title, style: readerTitleStyle(context))),
            if (written) ...[
              const SizedBox(height: 8),
              Text(
                s.reader_minutes(entry.minutes),
                style: TextStyle(fontSize: BazaarType.item.size, color: colors.onSurfaceMuted),
              ),
            ],
            const SizedBox(height: 24),
            if (doc.prerequisites.isNotEmpty) ...[
              PrerequisitesBox(refs: doc.prerequisites),
              const SizedBox(height: 24),
            ],
            if (doc.objectives.isNotEmpty) ...[ObjectivesCard(objectives: doc.objectives), const SizedBox(height: 26)],
            if (body != null)
              BlockList(blocks: body, render: render)
            else if (draft != null) ...[
              if (draft.summary case final summary?)
                BlockList(
                  blocks: [
                    ParagraphBlock(inlines: [TextInline(text: summary)], lead: true),
                  ],
                  render: render,
                ),
              if (draft.parts.isNotEmpty) ...[ScheduleOfParts(parts: draft.parts), const SizedBox(height: 26)],
              if (draft.written case final writtenBlocks?) BlockList(blocks: writtenBlocks, render: render),
            ],
            if (written) ...[
              const SizedBox(height: 16),
              CompletionRow(
                doc: doc,
                onToggle: () => context.read<ModuleReaderBloc>().add(const ReaderCompletionToggled()),
              ),
            ],
            const SizedBox(height: 32),
            Pager(previous: doc.previous, next: doc.next),
            if (quiz != null && quiz.isNotEmpty && quizBuilder != null) ...[
              const SizedBox(height: 32),
              quizBuilder(context, quiz),
            ],
            const SizedBox(height: 40),
            ReaderFooter(entry: entry, track: doc.track, moduleCount: moduleCount),
          ],
        ),
      ),
    );
  }

  /// Scrolls to the fragment once, after the first frame that draws the module.
  void _scheduleFragment() {
    final fragment = widget.fragment;
    if (fragment == null || _fragmentScheduled) return;
    _fragmentScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollTo(fragment);
    });
  }
}
