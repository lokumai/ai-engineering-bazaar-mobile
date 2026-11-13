import 'dart:async';

import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/completion_row.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/contents_sheet.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/find_bar.dart';
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
import 'package:ai_engineering_bazaar/shared/content/presentation/checklist_scope.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/text_find.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/link_actions.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/quiz_slot.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/reduced_motion.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/reading/application/reading_places_bloc.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/utils/grouped_number.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The module [moduleKey] in [track] (spec 3.6.3): opens a [ModuleReaderBloc] over the content index in context and
/// shows [ModuleReaderView], at the place the module was left on this device (plan 1BA), which it keeps as the reader
/// scrolls.
///
/// The app mounts the router only once the content is ready (spec 3.7), so any other content state is a fault. The
/// reader keeps the index it opened with (spec 3.4.4).
class ModuleReaderPage extends StatelessWidget {
  const ModuleReaderPage({
    super.key,
    required this.moduleKey,
    required this.track,
    this.fragment,
    this.query,
    this.quizBuilder,
  });

  final String moduleKey;
  final Track track;

  /// The heading to scroll to once the module is drawn, from a link to a section of the module.
  final String? fragment;

  /// The words searched in the catalog, marked in the module (plan 7.1).
  final String? query;

  /// Draws the quiz of a module that has one; null draws none (Decision A38).
  final QuizBuilder? quizBuilder;

  @override
  Widget build(BuildContext context) {
    final index = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index,
      final state => throw StateError('The reader needs ready content, not $state'),
    };
    final language = context.watch<LanguageCubit>().state;
    final places = context.read<ReadingPlacesBloc>();
    final record = context.read<RecordBloc>();
    // A completed module keeps no place: the reader has finished it, so it opens at its top (the owner, 2026-11-12).
    bool completed(RecordState state) => switch (state) {
      RecordReady(:final record) => record.signedOff(moduleKey, track) != null,
      RecordLoading() => false,
    };
    return BlocListener<RecordBloc, RecordState>(
      listenWhen: (before, now) => !completed(before) && completed(now),
      listener: (_, _) => places.add(ReadingPlaceCleared(track: track, module: moduleKey)),
      child: BlocProvider(
        // go_router keys a page by its route pattern, so a go to another module rebuilds this page with a new key;
        // the key makes that a new reader rather than the old module's, and a new language reopens the module in it.
        key: ValueKey((moduleKey, track, language)),
        create: (context) => ModuleReaderBloc(
          repository: context.read<IContentRepository>(),
          index: index,
          recordBloc: context.read<RecordBloc>(),
        )..add(ReaderOpened(key: moduleKey, track: track, language: language)),
        child: ModuleReaderView(
          fragment: fragment,
          query: query,
          quizBuilder: quizBuilder,
          place: completed(record.state) ? null : places.state.of(track, moduleKey),
          onPlace: (place) => places.add(
            place == null || completed(record.state)
                ? ReadingPlaceCleared(track: track, module: moduleKey)
                : ReadingPlaceKept(track: track, module: moduleKey, place: place),
          ),
        ),
      ),
    );
  }
}

/// The body of the reader, from the [ModuleReaderBloc] in context, in the web's order (`ModuleSheet.tsx:242-518`):
/// the contents button, the status band of a planned module, the title, the facts, the prerequisites, the objectives,
/// the body (or the summary, the schedule of parts and the written sections of a draft), the completion, the pager, the
/// quiz and the footer.
class ModuleReaderView extends StatefulWidget {
  const ModuleReaderView({super.key, this.fragment, this.query, this.quizBuilder, this.place, this.onPlace});

  final String? fragment;

  /// The words searched in the catalog: marked in the module, with a bar to step from one to the next (plan 7.1).
  final String? query;
  final QuizBuilder? quizBuilder;

  /// Where the module was left, to open it there; a [fragment] wins over it, as a link names its own place.
  final ReadingPlace? place;

  /// Told where the module is left each time a scroll ends; null once it is back at its top.
  final ValueChanged<ReadingPlace?>? onPlace;

  @override
  State<ModuleReaderView> createState() => _ModuleReaderViewState();
}

class _ModuleReaderViewState extends State<ModuleReaderView> {
  /// The key of each heading of [_keyedDoc], by heading id.
  final _headingKeys = <String, GlobalKey>{};
  ModuleDoc? _keyedDoc;

  bool _fragmentScheduled = false;

  /// The heading the page opened at, from a link or a search hit: kept at the top as the page's length changes, as a
  /// picture above it loads, until the reader scrolls.
  String? _held;

  /// The page's scroll, to open the module at [ModuleReaderView.place].
  final _scroll = ScrollController();

  bool _placeScheduled = false;

  /// Whether the page was scrolled by the reader or to a heading: the place is no longer applied as the page's length
  /// changes, as a picture loads.
  bool _moved = false;

  /// A place this near the top is no place: the module opens at its top.
  static const double _topSlack = 120;

  /// How far the module is read, from 0 to 1, by the scroll position on screen; drawn as the reading bar. The record
  /// keeps no reading position (R61); the place kept on this device is [ModuleReaderView.onPlace]'s.
  final _readProgress = ValueNotifier<double>(0);

  /// Marks the words searched; null when none were, or once the reader closed the bar.
  TextFinder? _finder;
  bool _findClosed = false;
  bool _findStarted = false;

  TextFinder? _finderFor(ModuleDoc doc) {
    final query = widget.query;
    if (_findClosed || query == null || query.trim().isEmpty) return null;
    return _finder ??= TextFinder(query: query, lang: context.read<LanguageCubit>().state)
      // A step to a mark moves the page: the heading it opened at is no longer held.
      ..onStep = () => _held = null;
  }

  void _closeFind() => setState(() {
    _finder?.dispose();
    _finder = null;
    _findClosed = true;
  });

  /// Makes the first mark under the heading the module opened at the current one, once it is drawn.
  void _scheduleFindStart() {
    final finder = _finder;
    if (finder == null || _findStarted) return;
    _findStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finder != finder) return;
      final fragment = widget.fragment;
      final box = fragment == null ? null : _headingKeys[fragment]?.currentContext?.findRenderObject();
      finder.startAt(box is RenderBox && box.attached ? box.localToGlobal(Offset.zero).dy : double.negativeInfinity);
    });
  }

  @override
  void dispose() {
    _finder?.dispose();
    _readProgress.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Follows the page's own scroll, not a nested one such as a wide table's: every scroll step, and every change of the
  /// page's length, as a picture that loads.
  bool _onScroll(Notification notification) {
    final (depth, metrics) = switch (notification) {
      ScrollUpdateNotification(:final depth, :final metrics) => (depth, metrics),
      ScrollMetricsNotification(:final depth, :final metrics) => (depth, metrics),
      _ => (-1, null),
    };
    if (notification case UserScrollNotification(depth: 0)) {
      _moved = true;
      _held = null;
    }
    if (notification case ScrollEndNotification(depth: 0, :final metrics)) _keepPlace(metrics);
    if (depth != 0 || metrics == null) return false;
    if (notification is ScrollMetricsNotification && !_moved) _applyPlace();
    if (notification is ScrollMetricsNotification) _holdHeading();
    _readProgress.value = metrics.maxScrollExtent <= 0 ? 1 : (metrics.pixels / metrics.maxScrollExtent).clamp(0, 1);
    return false;
  }

  GlobalKey _headingKey(String id) => _headingKeys.putIfAbsent(id, GlobalKey.new);

  /// Scrolls the heading [id] to the top, at once under reduced motion (spec 3.10). An id this module does not draw, as
  /// a fragment named in another language or for a module opened in English, leaves the page where it is. A move the
  /// reader chose lets go of the heading the page opened at.
  void _scrollTo(String id) {
    final target = _headingKeys[id]?.currentContext;
    if (target == null) return;
    _moved = true;
    _held = null;
    unawaited(Scrollable.ensureVisible(target, duration: motionDuration(context, BazaarMotion.shift)));
  }

  /// The scroll offset that brings the heading [id] to the top of the page, or null when it is not drawn.
  double? _headingOffset(String id) {
    final box = _headingKeys[id]?.currentContext?.findRenderObject();
    if (box == null || !box.attached) return null;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
  }

  /// Tells [ModuleReaderView.onPlace] where the page stands: the last heading above the top and the distance past it.
  void _keepPlace(ScrollMetrics metrics) {
    final onPlace = widget.onPlace;
    if (onPlace == null) return;
    if (metrics.pixels < _topSlack) {
      onPlace(null);
      return;
    }
    String? heading;
    var base = 0.0;
    for (final id in _headingKeys.keys) {
      final offset = _headingOffset(id);
      if (offset != null && offset <= metrics.pixels + 1 && offset >= base) {
        heading = id;
        base = offset;
      }
    }
    onPlace(
      ReadingPlace(
        heading: heading,
        offset: metrics.pixels - base,
        share: metrics.maxScrollExtent <= 0 ? 1 : (metrics.pixels / metrics.maxScrollExtent).clamp(0, 1),
        at: clock.now(),
      ),
    );
  }

  /// Scrolls to [ModuleReaderView.place]: its heading and the distance past it, or its share of the page when the
  /// heading is gone from the module.
  void _applyPlace() {
    final place = widget.place;
    if (place == null || widget.fragment != null || !_placeScheduled || !_scroll.hasClients) return;
    final position = _scroll.position;
    final heading = place.heading;
    final base = heading == null ? 0.0 : _headingOffset(heading);
    final target = base == null ? place.share * position.maxScrollExtent : base + place.offset;
    final clamped = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((clamped - position.pixels).abs() > 0.5) _scroll.jumpTo(clamped);
  }

  /// Brings the heading the page opened at back to the top, after a picture above it changed the page's length.
  void _holdHeading() {
    final id = _held;
    if (id == null || !_scroll.hasClients) return;
    final base = _headingOffset(id);
    if (base == null) return;
    final position = _scroll.position;
    final target = base.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() > 0.5) _scroll.jumpTo(target);
  }

  /// Opens the contents sheet and scrolls to the heading chosen once the sheet is gone.
  Future<void> _openContents(List<TocEntry> sections) async {
    final id = await showContentsSheet(context, sections);
    if (id != null && mounted) _scrollTo(id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModuleReaderBloc, ReaderState>(
      builder: (context, state) => switch (state) {
        ReaderLoading() => Scaffold(
          body: Center(child: CircularProgressIndicator(semanticsLabel: S.of(context).loading)),
        ),
        ReaderNotFound() => const Scaffold(body: NotFoundView()),
        ReaderFailed() => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).reader_failed),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.read<ModuleReaderBloc>().add(const ReaderRetried()),
                  child: Text(S.of(context).reader_retry),
                ),
              ],
            ),
          ),
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
    _schedulePlace();
    final finder = _finderFor(doc);
    _scheduleFindStart();

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
    final level = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index.level(entry.level),
      _ => null,
    };

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The reading bar: decoration, as the scroll position it shows is on screen already.
          ExcludeSemantics(
            child: ValueListenableBuilder<double>(
              valueListenable: _readProgress,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                color: BazaarFixedColors.success,
                backgroundColor: colors.surfaceSunken,
              ),
            ),
          ),
          if (finder != null) FindBar(finder: finder, onClose: _closeFind),
          Expanded(
            child: NotificationListener<Notification>(
              onNotification: _onScroll,
              child: _checklistScope(
                doc,
                _findScope(
                  finder,
                  SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (sections.isNotEmpty)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: () => unawaited(_openContents(sections)),
                              icon: const Icon(Icons.toc),
                              label: Text(s.reader_contents),
                            ),
                          ),
                        if (draft != null && !written) ...[
                          StatusBand(partlyWritten: draft.written != null),
                          const SizedBox(height: 20),
                        ],
                        // The level and the module's number over the title (the mockup's line; both are the index's).
                        if (level != null)
                          Text(
                            '${level.title} · ${entry.number.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
                          ),
                        Semantics(header: true, child: Text(doc.title, style: readerTitleStyle(context))),
                        if (written) ...[
                          const SizedBox(height: 8),
                          Text(
                            // The minutes and the words as the module's web page prints them under its title (web D128).
                            switch (doc.words) {
                              final words? => s.length_minutes_words(entry.minutes, groupedNumber(words, doc.lang)),
                              null => s.reader_minutes(entry.minutes),
                            },
                            style: TextStyle(fontSize: BazaarType.item.size, color: colors.onSurfaceMuted),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (doc.prerequisites.isNotEmpty) ...[
                          PrerequisitesBox(refs: doc.prerequisites),
                          const SizedBox(height: 24),
                        ],
                        if (doc.shownObjectives.isNotEmpty) ...[
                          ObjectivesCard(objectives: doc.shownObjectives),
                          const SizedBox(height: 26),
                        ],
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
                          if (draft.parts.isNotEmpty) ...[
                            ScheduleOfParts(parts: draft.parts),
                            const SizedBox(height: 26),
                          ],
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
                          quizBuilder(context, entry.key, quiz),
                        ],
                        const SizedBox(height: 40),
                        ReaderFooter(entry: entry, track: doc.track, moduleCount: moduleCount),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The scope stands whether or not anything is searched, so closing the find bar keeps the page's scroll view, and
  /// with it the place the reader is at, rather than building a new one at the top.
  static Widget _findScope(TextFinder? finder, Widget child) => TextFindScope(finder: finder, child: child);

  /// The module's checklist, live (web `ChecklistIsland`, D129): its boxes show the reader's ticks and change them in
  /// the record, under the module's key in the document's track.
  static Widget _checklistScope(ModuleDoc doc, Widget child) => BlocSelector<RecordBloc, RecordState, Set<int>>(
    selector: (state) => state is RecordReady ? state.record.ticks(doc.key, doc.track) : const {},
    builder: (context, ticks) => ChecklistScope(
      ticks: ticks,
      onToggle: (index, {required ticked}) => context.read<RecordBloc>().add(
        ChecklistItemToggled(key: doc.key, index: index, ticked: ticked, track: doc.track),
      ),
      child: child,
    ),
  );

  /// Scrolls to the place the module was left once, after the first frame that draws the module; again as the page's
  /// length changes until the reader scrolls.
  void _schedulePlace() {
    if (widget.place == null || widget.fragment != null || _placeScheduled) return;
    _placeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyPlace();
    });
  }

  /// Scrolls to the fragment once, after the first frame that draws the module, and holds it there as pictures above
  /// it load, until the reader scrolls.
  void _scheduleFragment() {
    final fragment = widget.fragment;
    if (fragment == null || _fragmentScheduled) return;
    _fragmentScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollTo(fragment);
      _held = fragment;
    });
  }
}
