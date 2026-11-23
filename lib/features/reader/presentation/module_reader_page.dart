import 'dart:async';

import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/features/reader/application/module_reader_bloc.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/spoken_parts.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/completion_row.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/contents_sheet.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/find_bar.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/listen_player.dart';
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
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
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
import 'package:ai_engineering_bazaar/features/reader/domain/read_enough.dart';
import 'package:ai_engineering_bazaar/shared/widgets/not_found_view.dart';
import 'package:clock/clock.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_scope.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/section_spine.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/readable_width.dart';
import 'package:ai_engineering_bazaar/features/reader/presentation/widgets/term_bubble.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/term_scope.dart';
import 'package:ai_engineering_bazaar/shared/review/application/review_bloc.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_card.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/module_notes.dart';
import 'package:ai_engineering_bazaar/shared/study/domain/term_marks.dart';
import 'package:ai_engineering_bazaar/shared/study/presentation/study_notes_loader.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:ai_engineering_bazaar/shared/design_system/share_icon.dart';
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
    this.keepsPlace = true,
  });

  final String moduleKey;
  final Track track;

  /// The heading to scroll to once the module is drawn, from a link to a section of the module.
  final String? fragment;

  /// The words searched in the catalog, marked in the module (plan 7.1).
  final String? query;

  /// Draws the quiz of a module that has one; null draws none (Decision A38).
  final QuizBuilder? quizBuilder;

  /// Whether the module keeps where it is left. One opened from the day's card keeps none, however far it is scrolled:
  /// a look at the day's card is not the module being read (the owner, 2026-11-17).
  final bool keepsPlace;

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
    // The glossary's terms are marked in the module's text (plan 13.9); the notes hold them.
    return StudyNotesLoader(
      child: BlocListener<RecordBloc, RecordState>(
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
            onPlace: !keepsPlace
                ? null
                : (place) => places.add(
                    place == null || completed(record.state)
                        ? ReadingPlaceCleared(track: track, module: moduleKey)
                        : ReadingPlaceKept(track: track, module: moduleKey, place: place),
                  ),
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

  /// Whether the reader has scrolled the page with their own hand. Until then no place is kept: a module opened at a
  /// section from the day's card or a search hit, and only looked at, is not where the reader left off (the owner,
  /// 2026-11-16).
  bool _readerScrolled = false;

  /// A place this near the top is the module's top: read and gone back up, the module is still the one being read, and
  /// opens at its top (the owner, 2026-11-17, back at the top by the status bar).
  static const double _topSlack = 120;

  /// How far the module is read, from 0 to 1, by the scroll position on screen; drawn as the reading bar. The record
  /// keeps no reading position (R61); the place kept on this device is [ModuleReaderView.onPlace]'s.
  final _readProgress = ValueNotifier<double>(0);

  /// The section in view, for the sections beside the text on a wide screen (plan 12.10); null above the first.
  final _currentSection = ValueNotifier<String?>(null);

  /// The ids of the module's sections, as last drawn.
  List<String> _sectionIds = const [];

  /// The glossary's terms in the module's text (plan 13.9), worked out once for [_marksOf].
  Map<TextInline, List<TermMark>> _marks = const {};
  (ModuleDoc, StudyNotesReady)? _marksOf;

  /// The parts of [_partsOf] the voice reads (plan 15), worked out once for each document drawn; none for a planned
  /// one. The reading itself is the app's ([ListenCubit]): it goes on as the reader leaves the module (the owner,
  /// 2026-11-18).
  List<SpokenPart> _parts = const [];
  ModuleDoc? _partsOf;

  /// Whether the phone has a voice for [_voiceFor], the module's language; null until it answers.
  bool? _voice;
  String? _voiceFor;

  /// The place in the body of the block read aloud now; null while none is.
  final _spoken = ValueNotifier<int?>(null);

  /// The key of each block of the body, by its place, to follow the voice.
  final _blockKeys = <int, GlobalKey>{};

  /// Stops [_onScreen] while the app is off the screen; the reading aloud goes on (the owner, 2026-11-18).
  late final AppLifecycleListener _lifecycle;

  /// How long the module has been on the screen in this visit; over every visit with the place's [ReadingPlace.seconds].
  final _onScreen = clock.stopwatch();

  /// Whether the module's end, its completion row, has come into view.
  bool _reachedEnd = false;

  /// The key of the completion row, the module's end.
  final _endKey = GlobalKey();

  /// The place last kept in this visit, which leaving keeps again with the time spent.
  ReadingPlace? _lastPlace;

  /// What marks the module completed as it is left, kept while it is drawn: a page being taken down can read nothing
  /// around it. Null while no written module is drawn.
  _Leaving? _leaving;

  /// The seconds the module has been on the screen, over every visit.
  int get _seconds => (widget.place?.seconds ?? 0) + _onScreen.elapsed.inSeconds;

  @override
  void initState() {
    super.initState();
    _onScreen.start();
    _lifecycle = AppLifecycleListener(onHide: _onScreen.stop, onShow: _onShow);
  }

  void _onShow() {
    _onScreen.start();
    // Back from the phone's settings, where the line said to add a voice: the phone is asked again (review 5,
    // finding 9).
    if (_voice == false) setState(() => _voiceFor = null);
  }

  /// The parts of [doc] to read aloud, worked out when a document with a body is first drawn, and the phone asked for a
  /// voice in its language.
  List<SpokenPart> _partsFor(BuildContext context, ModuleDoc doc) {
    final body = doc.body;
    if (body == null) return const [];
    if (!identical(_partsOf, doc) && _partsOf != doc) {
      _blockKeys.clear();
      _spoken.value = null;
      _partsOf = doc;
      _parts = spokenParts(body);
    }
    final language = doc.lang;
    if (_voiceFor != language) {
      _voiceFor = language;
      _voice = null;
      unawaited(
        context.read<ListenCubit>().canSpeak(language).then((can) {
          if (mounted && _voiceFor == language) setState(() => _voice = can);
        }),
      );
    }
    return _parts;
  }

  /// Whether [state] reads the module drawn.
  bool _readsThis(ListenState state) => switch ((state, _partsOf)) {
    (final ListenOn on, final doc?) => on.reads(doc.key, doc.track),
    _ => false,
  };

  GlobalKey _blockKey(int index) => _blockKeys.putIfAbsent(index, GlobalKey.new);

  /// Marks the block read now and brings it near the page's top as the voice moves on to it.
  void _followVoice(BuildContext context, ListenState state) {
    final block = switch (state) {
      ListenOn(:final index) when _readsThis(state) && index < _parts.length => _parts[index].block,
      _ => null,
    };
    if (_spoken.value == block) return;
    _spoken.value = block;
    final target = block == null ? null : _blockKeys[block]?.currentContext;
    if (target == null) return;
    _moved = true;
    _held = null;
    unawaited(Scrollable.ensureVisible(target, alignment: 0.1, duration: motionDuration(context, BazaarMotion.fold)));
  }

  /// The term whose definition is shown in a bubble, and where it was tapped; null when none is.
  GlossaryTerm? _bubble;
  Offset? _bubbleAt;

  /// The terms of [doc] from the notes of its track: the module's own first, then the others'. The Key Terms and the
  /// References are not marked.
  Map<TextInline, List<TermMark>> _termMarksFor(BuildContext context, ModuleDoc doc) {
    final notes = switch (context.watch<StudyNotesCubit>().state) {
      final StudyNotesReady ready when ready.track == doc.track => ready,
      _ => null,
    };
    final body = doc.body;
    if (notes == null || body == null) return const {};
    if (_marksOf case (final marked, final read) when identical(marked, doc) && identical(read, notes)) return _marks;
    final own = notes.of(doc.key);
    final last = [
      for (final block in body)
        if (block case HeadingBlock(depth: 2, :final id)) id,
    ].lastOrNull;
    _marksOf = (doc, notes);
    return _marks = termMarks(
      body,
      [
        ...?own?.terms,
        for (final module in notes.modules)
          if (module.moduleKey != doc.key) ...module.terms,
      ],
      skip: {?own?.termsHeading, ?last},
    );
  }

  /// Shows [term]'s definition in a bubble by [at], and keeps the term as looked up (plan 13.3).
  void _showTerm(GlossaryTerm term, Offset? at) {
    context.read<ReviewBloc>().add(
      ReviewTermLookedUp(termKey(_marksOf?.$2.track ?? Track.engineers, term.moduleKey, term.index)),
    );
    // The bubble stands in the page's own box, which starts where this view does: no bar is over it.
    final box = context.findRenderObject();
    setState(() {
      _bubble = term;
      _bubbleAt = at != null && box is RenderBox && box.hasSize ? box.globalToLocal(at) : null;
    });
  }

  void _closeTerm() => setState(() => _bubble = null);

  /// Marks the words searched; null when none were, or once the reader closed the bar.
  TextFinder? _finder;
  bool _findClosed = false;
  bool _findStarted = false;

  TextFinder? _finderFor(ModuleDoc doc) {
    final query = widget.query;
    if (_findClosed || query == null || query.trim().isEmpty) return null;
    return _finder ??= TextFinder(query: query, lang: context.read<LanguageCubit>().state)
      // A step to a mark moves the page: the heading it opened at is no longer held, nor the place it was left at,
      // which a picture that loads would otherwise scroll back to.
      ..onStep = () {
        _held = null;
        _moved = true;
      };
  }

  void _closeFind() => setState(() {
    _finder?.dispose();
    _finder = null;
    _findClosed = true;
  });

  /// Makes the first mark under the heading the module opened at the current one, once it is drawn; with no heading,
  /// the first mark the page shows, a frame later, once the page stands where the module was left.
  void _scheduleFindStart() {
    final finder = _finder;
    if (finder == null || _findStarted) return;
    _findStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finder != finder) return;
      final fragment = widget.fragment;
      if (fragment == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _finder == finder) finder.startInView();
        });
        WidgetsBinding.instance.scheduleFrame();
        return;
      }
      final box = _headingKeys[fragment]?.currentContext?.findRenderObject();
      finder.startAt(box is RenderBox && box.attached ? box.localToGlobal(Offset.zero).dy : double.negativeInfinity);
    });
  }

  @override
  void dispose() {
    _leave();
    _lifecycle.dispose();
    _spoken.dispose();
    _finder?.dispose();
    _readProgress.dispose();
    _currentSection.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// As the module is left, to the next one, back or to another tab (the owner, 2026-11-18): one read to its end, and on
  /// the screen long enough ([readEnough]), is marked completed, with Undo; otherwise the place is kept with the time
  /// spent. A module already completed is left as it is.
  void _leave() {
    _onScreen.stop();
    final leaving = _leaving;
    if (leaving == null) return;
    final record = leaving.record;
    final doc = leaving.doc;
    final completed = switch (record.state) {
      RecordReady(:final record) => record.signedOff(doc.key, doc.track) != null,
      RecordLoading() => true,
    };
    if (completed) return;
    final seconds = _seconds;
    if (!readEnough(reachedEnd: _reachedEnd, seconds: seconds, minutes: leaving.minutes)) {
      final last = _lastPlace ?? widget.place;
      if (last != null && seconds > last.seconds) widget.onPlace?.call(last.withSeconds(seconds));
      return;
    }
    final toggle = CompletionToggled(key: doc.key, track: doc.track, revision: leaving.revision);
    record.add(toggle);
    widget.onPlace?.call(null);
    final messenger = leaving.messenger;
    if (messenger == null) return;
    // The tree is being taken down: the note waits for the next frame, on the page the reader went to.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          key: const ValueKey('reader-auto-completed'),
          content: Text(leaving.said),
          action: SnackBarAction(label: leaving.undo, onPressed: () => record.add(toggle)),
        ),
      );
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Whether the module's end, its completion row, is in view at [metrics].
  bool _endInView(ScrollMetrics metrics) {
    final box = _endKey.currentContext?.findRenderObject();
    if (box == null || !box.attached) return false;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 1).offset <= metrics.pixels + 1;
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
      _readerScrolled = true;
    }
    if (notification case ScrollEndNotification(depth: 0, :final metrics) when _readerScrolled) _keepPlace(metrics);
    if (depth != 0 || metrics == null) return false;
    if (!_reachedEnd) _reachedEnd = _endInView(metrics);
    if (notification is ScrollMetricsNotification && !_moved) _applyPlace();
    if (notification is ScrollMetricsNotification) _holdHeading();
    _readProgress.value = metrics.maxScrollExtent <= 0 ? 1 : (metrics.pixels / metrics.maxScrollExtent).clamp(0, 1);
    _currentSection.value = _sectionAt(metrics.pixels);
    return false;
  }

  /// The section whose heading is the last one at or above [pixels], a little below the top counting.
  String? _sectionAt(double pixels) {
    String? found;
    var base = double.negativeInfinity;
    for (final id in _sectionIds) {
      final offset = _headingOffset(id);
      if (offset != null && offset <= pixels + 24 && offset >= base) {
        found = id;
        base = offset;
      }
    }
    return found;
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
    void keep(ReadingPlace place) => onPlace(_lastPlace = place);
    if (metrics.pixels < _topSlack) {
      keep(ReadingPlace(offset: 0, share: 0, at: clock.now(), seconds: _seconds));
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
    keep(
      ReadingPlace(
        heading: heading,
        offset: metrics.pixels - base,
        share: metrics.maxScrollExtent <= 0 ? 1 : (metrics.pixels / metrics.maxScrollExtent).clamp(0, 1),
        at: clock.now(),
        seconds: _seconds,
      ),
    );
  }

  /// Scrolls to [ModuleReaderView.place]: its heading and the distance past it, or its share of the page when the
  /// heading is gone from the module.
  void _applyPlace() {
    final place = widget.place;
    if (place == null || widget.fragment != null || !_placeScheduled || !_scroll.hasClients) return;
    final position = _scroll.position;
    // Built under another page, the module is not laid out and has no length yet; the change of metrics as it comes
    // to the front calls this again (Sentry AI-BAZAAR-MOBILE-3).
    if (!position.hasContentDimensions) return;
    final heading = place.heading;
    final base = heading == null ? 0.0 : _headingOffset(heading);
    final target = base == null ? place.share * position.maxScrollExtent : base + place.offset;
    final clamped = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((clamped - position.pixels).abs() > 0.5) _scroll.jumpTo(clamped);
  }

  /// Brings the heading the page opened at back to the top, after a picture above it changed the page's length.
  void _holdHeading() {
    final id = _held;
    if (id == null || !_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
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
    final parts = _partsFor(context, doc);
    final listen = context.read<ListenCubit>();
    // Back on the module being read aloud, the page goes to where the voice is.
    if (_spoken.value == null && _readsThis(listen.state)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _followVoice(context, listen.state);
      });
    }

    final index = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index,
      final state => throw StateError('The reader needs ready content, not $state'),
    };
    final diagramThemes = index.diagramThemes;
    _leaving = !written
        ? null
        : _Leaving(
            doc: doc,
            minutes: entry.minutes,
            revision: entry.tracks[doc.track]?.revision?.hash,
            record: context.read<RecordBloc>(),
            messenger: ScaffoldMessenger.maybeOf(context),
            said: s.reader_auto_completed,
            undo: s.data_undo,
          );
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
    _sectionIds = [for (final section in sections) section.id];
    final quiz = doc.quiz;
    final quizBuilder = widget.quizBuilder;
    final level = switch (context.read<ContentBloc>().state) {
      ContentReady(:final index) => index.level(entry.level),
      _ => null,
    };

    final page = Scaffold(
      body: Stack(
        // The page fills the screen as it did before the bubble stood over it.
        fit: StackFit.expand,
        children: [
          Column(
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
                child: _withSections(
                  context,
                  sections,
                  (spine) => NotificationListener<Notification>(
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
                              if (sections.isNotEmpty && !spine)
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
                              // The title as marked text: the catalog finds a module by its title, so its words are marked.
                              Semantics(
                                header: true,
                                child: InlineText(
                                  inlines: [TextInline(text: doc.title)],
                                  style: readerTitleStyle(context),
                                  onLink: (_) {},
                                ),
                              ),
                              if (written) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        // The minutes and the words as the module's web page prints them under its
                                        // title (web D128).
                                        switch (doc.words) {
                                          final words? => s.length_minutes_words(
                                            entry.minutes,
                                            groupedNumber(words, doc.lang),
                                          ),
                                          null => s.reader_minutes(entry.minutes),
                                        },
                                        style: TextStyle(fontSize: BazaarType.item.size, color: colors.onSurfaceMuted),
                                      ),
                                    ),
                                    // The module's page on the site, at the address the bundle gives it (D111), through
                                    // the phone's share sheet (plan 17.3); the site's links open in the app where it is
                                    // installed (plan 17.2).
                                    IconButton(
                                      key: const ValueKey('reader-share'),
                                      tooltip: s.reader_share,
                                      icon: Icon(shareIcon(context), size: 20, color: colors.onSurfaceMuted),
                                      onPressed: () => context.read<IShareSheet>().share(
                                        '${doc.title}\n${context.read<WebLinks>().webPage(entry.tracks[doc.track]!.webPath)}',
                                      ),
                                    ),
                                  ],
                                ),
                                // Listen, with a voice for the module's language (plan 15.1), unless it is being read;
                                // once listened to, it goes on from where it was left (the owner, 2026-11-18).
                                if (_voice == true && parts.isNotEmpty)
                                  BlocBuilder<ListenCubit, ListenState>(
                                    // Also when nothing is read: the places kept come in, or another module ends.
                                    buildWhen: (before, now) =>
                                        _readsThis(before) != _readsThis(now) || now is ListenIdle,
                                    builder: (context, state) => _readsThis(state)
                                        ? const SizedBox.shrink()
                                        : Align(
                                            alignment: AlignmentDirectional.centerStart,
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: OutlinedButton.icon(
                                                key: const ValueKey('reader-listen'),
                                                onPressed: () => listen.start(
                                                  ListenSession(
                                                    module: doc.key,
                                                    track: doc.track,
                                                    title: doc.title,
                                                    language: doc.lang,
                                                    parts: parts,
                                                  ),
                                                ),
                                                icon: const Icon(Icons.headphones_rounded, size: 18),
                                                label: Text(
                                                  listen.keptAt(doc.key, doc.track) == null
                                                      ? s.listen
                                                      : s.listen_resume,
                                                ),
                                              ),
                                            ),
                                          ),
                                  )
                                // No voice for the module's language, as often for Persian on Android: a line says
                                // where to add one, rather than Listen missing without a word (plan 20.6).
                                else if (_voice == false && parts.isNotEmpty)
                                  Padding(
                                    key: const ValueKey('reader-no-voice'),
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      spacing: 8,
                                      children: [
                                        Icon(Icons.headset_off_rounded, size: 18, color: colors.onSurfaceMuted),
                                        Expanded(
                                          child: Text(
                                            s.listen_no_voice,
                                            style: Theme.of(context).textTheme.bodySmall
                                                ?.copyWith(color: colors.onSurfaceMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 24),
                              if (doc.prerequisites.isNotEmpty) ...[
                                ReadingStyleScope(child: PrerequisitesBox(refs: doc.prerequisites)),
                                const SizedBox(height: 24),
                              ],
                              if (doc.shownObjectives.isNotEmpty) ...[
                                ReadingStyleScope(child: ObjectivesCard(objectives: doc.shownObjectives)),
                                const SizedBox(height: 26),
                              ],
                              // The module's text in the reader's reading settings (plan 12.5); its title and bars keep theirs.
                              if (body != null)
                                TermScope(
                                  marks: _termMarksFor(context, doc),
                                  onTap: _showTerm,
                                  child: ReadingStyleScope(
                                    child: BlockList(
                                      blocks: body,
                                      render: render,
                                      spoken: parts.isEmpty ? null : SpokenBlocks(at: _spoken, keyOf: _blockKey),
                                    ),
                                  ),
                                )
                              else if (draft != null) ...[
                                if (draft.summary case final summary?)
                                  ReadingStyleScope(
                                    child: BlockList(
                                      blocks: [
                                        ParagraphBlock(inlines: [TextInline(text: summary)], lead: true),
                                      ],
                                      render: render,
                                    ),
                                  ),
                                if (draft.parts.isNotEmpty) ...[
                                  ScheduleOfParts(parts: draft.parts),
                                  const SizedBox(height: 26),
                                ],
                                if (draft.written case final writtenBlocks?)
                                  ReadingStyleScope(
                                    child: BlockList(blocks: writtenBlocks, render: render),
                                  ),
                              ],
                              if (written) ...[
                                const SizedBox(height: 16),
                                // The module's end, which counts it read once in view (the owner, 2026-11-18).
                                KeyedSubtree(
                                  key: _endKey,
                                  child: CompletionRow(
                                    doc: doc,
                                    onToggle: () =>
                                        context.read<ModuleReaderBloc>().add(const ReaderCompletionToggled()),
                                  ),
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
              ),
              // The player while the module is read aloud (plan 15.1).
              if (parts.isNotEmpty)
                BlocBuilder<ListenCubit, ListenState>(
                  builder: (context, state) => switch (state) {
                    final ListenOn on when _readsThis(on) => ListenPlayer(state: on),
                    ListenOn() || ListenIdle() => const SizedBox.shrink(),
                  },
                ),
            ],
          ),
          // A term's definition over the text (plan 13.9); a tap anywhere else closes it.
          if (_bubble case final term?) ...[
            Positioned.fill(
              child: ModalBarrier(
                key: const ValueKey('term-barrier'),
                dismissible: true,
                onDismiss: _closeTerm,
                semanticsLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
              ),
            ),
            TermBubble(term: term, at: _bubbleAt),
          ],
        ],
      ),
    );
    if (parts.isEmpty) return page;
    return BlocListener<ListenCubit, ListenState>(listener: _followVoice, child: page);
  }

  /// The module's text, with its sections beside it when the page is wide enough for both, an iPad in landscape (plan
  /// 12.10, the web's section spine). [text] is told whether they stand beside it, which then replaces the contents
  /// button. The text comes first in the tree, so the status bar's tap scrolls it and not the sections; a row laid out
  /// the other way round puts the sections at the start.
  Widget _withSections(BuildContext context, List<TocEntry> sections, Widget Function(bool spine) text) =>
      LayoutBuilder(
        builder: (context, constraints) {
          // One column keeps a phone's measure, as every other page.
          if (sections.isEmpty || constraints.maxWidth < ReadableWidth.withSections - 1) {
            return ReadableWidth(child: text(false));
          }
          final ltr = Directionality.of(context) == TextDirection.ltr;
          return Row(
            textDirection: ltr ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: text(true)),
              const SizedBox(width: ReadableWidth.gap),
              SizedBox(
                width: ReadableWidth.sections,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, top: 24),
                  child: SectionSpine(sections: sections, current: _currentSection, onTap: _scrollTo),
                ),
              ),
            ],
          );
        },
      );

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

/// What [_ModuleReaderViewState._leave] needs of a written module and the app around it.
final class _Leaving {
  const _Leaving({
    required this.doc,
    required this.minutes,
    required this.revision,
    required this.record,
    required this.messenger,
    required this.said,
    required this.undo,
  });

  final ModuleDoc doc;

  /// The module's minutes, a third of which on the screen counts it read.
  final int minutes;

  /// The revision its completion carries (A35).
  final String? revision;
  final RecordBloc record;
  final ScaffoldMessengerState? messenger;

  /// The note that it was marked, and its Undo, in the interface's language.
  final String said;
  final String undo;
}
