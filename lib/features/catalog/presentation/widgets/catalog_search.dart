import 'dart:async';

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_query_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/reader_target.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The field at the head of the catalog where the reader types words to find (plan 7.1). The query is searched a
/// moment after the last key, so a fast typist is not searched letter by letter.
class CatalogSearchField extends StatefulWidget {
  const CatalogSearchField({super.key});

  /// How long the field waits after a key before it searches.
  static const settle = Duration(milliseconds: 200);

  @override
  State<CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends State<CatalogSearchField> {
  // The words kept from the last time the catalog was shown.
  late final _controller = TextEditingController(text: context.read<CatalogQueryCubit>().state);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    setState(() {});
    context.read<CatalogQueryCubit>().keep(text);
    _timer?.cancel();
    final cubit = context.read<CatalogSearchCubit>();
    if (text.trim().isEmpty) {
      cubit.clear();
      return;
    }
    _timer = Timer(CatalogSearchField.settle, () => unawaited(cubit.search(text)));
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    context.read<CatalogQueryCubit>().keep('');
    context.read<CatalogSearchCubit>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return TextField(
      controller: _controller,
      onChanged: _changed,
      onSubmitted: (text) {
        _timer?.cancel();
        unawaited(context.read<CatalogSearchCubit>().search(text));
      },
      textInputAction: TextInputAction.search,
      // A tap elsewhere puts the keyboard away: iOS has no back key to do it.
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: s.catalog_search_hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.close, size: 20), tooltip: s.catalog_search_clear, onPressed: _clear),
        border: const OutlineInputBorder(),
        isDense: true,
        // 48 high, the least a tap target may be.
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// The hits of the catalog's search in place of the levels (plan 7.1): the levels to keep the hits to (plan 10.2), how
/// many, then one card per module, in the order of its best hit, under its level's hue, with the module's name and each
/// matching section under it, its heading and the words around the match, the matched words in bold. A module with more
/// than one hit is folded to its best one (plan 10.1, the owner's testers, 2026-11-16: seven sections of one module
/// filled the screen); a tap unfolds it. A section opens its module at that section; either way the words searched are
/// marked in the module.
class CatalogSearchResults extends StatelessWidget {
  const CatalogSearchResults({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogSearchCubit>().state;
    final s = S.of(context);
    final muted = context.bazaarColors.onSurfaceMuted;
    final textTheme = Theme.of(context).textTheme;
    final results = state.results;
    if (results == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final hits = results.hits;
    // The levels stay to choose from while a choice finds nothing, so it can be undone.
    final filter = results.levels.isEmpty ? null : _LevelFilter(found: results.levels, chosen: state.levels);
    final other = state.other;
    if (hits.isEmpty && other != null && other.hits.isNotEmpty) {
      // Nothing in the reader's track, so the other track's hits (plan 12.7); opened, the track stays.
      final otherTrack = track.other;
      return Column(
        key: const ValueKey('catalog-search-other-track'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              s.catalog_search_none_here(state.query.trim()),
              style: textTheme.bodyLarge?.copyWith(color: muted),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${s.catalog_search_other_track(trackName(s, otherTrack))} · ${s.catalog_search_count(other.total)}',
            style: textTheme.labelLarge?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final MapEntry(key: module, value: group) in _byModule(other.hits).entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ModuleHits(
                key: ValueKey('other-$module'),
                hits: group,
                track: otherTrack,
                query: state.query,
                visit: true,
              ),
            ),
        ],
      );
    }
    if (hits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?filter,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Semantics(
              liveRegion: true,
              child: Text(
                s.catalog_search_none(state.query.trim()),
                style: textTheme.bodyLarge?.copyWith(color: muted),
              ),
            ),
          ),
        ],
      );
    }
    final groups = _byModule(hits);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?filter,
        Semantics(
          liveRegion: true,
          child: Text(
            results.total > hits.length
                ? '${s.catalog_search_count(results.total)} · ${s.catalog_search_shown(hits.length)}'
                : s.catalog_search_count(results.total),
            style: textTheme.labelLarge?.copyWith(color: muted),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final MapEntry(key: module, value: group) in groups.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            // Keyed by the module, so one unfolded stays so while the reader types on.
            child: _ModuleHits(key: ValueKey(module), hits: group, track: track, query: state.query),
          ),
      ],
    );
  }
}

/// [hits] by their module, in the order of each module's best hit.
Map<String, List<SearchHit>> _byModule(List<SearchHit> hits) {
  final groups = <String, List<SearchHit>>{};
  for (final hit in hits) {
    (groups[hit.entry.moduleKey] ??= []).add(hit);
  }
  return groups;
}

/// The levels the hits can be kept to (plan 10.2): All, then each level with hits, how many in it; more than one level
/// may be chosen, and All chooses every level again.
class _LevelFilter extends StatelessWidget {
  const _LevelFilter({required this.found, required this.chosen});

  /// How many hits each level has, by slug.
  final Map<String, int> found;

  /// The levels chosen, by slug; none for every level.
  final Set<String> chosen;

  /// The key of a level's choice.
  static Key keyOf(String level) => ValueKey('catalog-search-level-$level');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<CatalogSearchCubit>();
    final index = (context.read<ContentBloc>().state as ContentReady).index;
    // In the course's order, a level chosen kept even when the words typed now find nothing in it.
    final levels = [
      for (final level in index.levels)
        if (found.containsKey(level.slug) || chosen.contains(level.slug)) level,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        label: s.catalog_search_levels,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                key: keyOf(''),
                label: Text(s.catalog_search_all_levels),
                selected: chosen.isEmpty,
                onSelected: (_) => unawaited(cubit.filter(const {})),
              ),
              for (final level in levels)
                FilterChip(
                  key: keyOf(level.slug),
                  label: Text('${level.title} · ${found[level.slug] ?? 0}'),
                  selected: chosen.contains(level.slug),
                  onSelected: (on) =>
                      unawaited(cubit.filter(on ? {...chosen, level.slug} : chosen.difference({level.slug}))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One module's hits in a card, the level's hue across its top. With more than one hit it is folded (plan 10.1): its
/// name, how many hits, and the best one; a tap on its head unfolds it to a row that opens the module and every hit.
class _ModuleHits extends StatefulWidget {
  const _ModuleHits({super.key, required this.hits, required this.track, required this.query, this.visit = false});

  final List<SearchHit> hits;
  final Track track;
  final String query;

  /// Whether the hits are of the other track (plan 12.7): opened, the reader's track stays as it is.
  final bool visit;

  @override
  State<_ModuleHits> createState() => _ModuleHitsState();
}

class _ModuleHitsState extends State<_ModuleHits> {
  bool _open = false;

  List<SearchHit> get _hits => widget.hits;

  bool get _level => _hits.first.entry.kind == SearchKind.level;

  /// Whether the card folds: a module with more than one hit.
  bool get _folds => !_level && _hits.length > 1;

  /// Opens the module at [fragment] with the words searched marked, or the level's page for a level.
  void _go(BuildContext context, String? fragment) => _level
      ? context.push(BazaarPaths.level(widget.track, _hits.first.entry.moduleKey))
      : context.push(
          BazaarPaths.module(widget.track, _hits.first.entry.moduleKey),
          extra: ReaderTarget(fragment: fragment, query: widget.query, visit: widget.visit),
        );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final first = _hits.first.entry;
    final index = (context.read<ContentBloc>().state as ContentReady).index;
    final level = _level ? index.level(first.moduleKey) : null;
    final hue = levelHue(context, levelPosition(index, first.moduleKey.split('/').first));
    final mark = TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface);
    final still = MediaQuery.disableAnimationsOf(context);
    Widget hitRow(SearchHit hit, {bool folded = false}) => InkWell(
      onTap: folded ? () => setState(() => _open = true) : () => _go(context, hit.entry.sectionId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hit.entry.kind == SearchKind.section)
              Text(hit.entry.section, style: textTheme.labelLarge?.copyWith(color: colors.onSurface)),
            if (hit.excerpt.isNotEmpty)
              Text.rich(
                _marked(hit, mark),
                style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted),
                maxLines: folded ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
    final head = Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (!_level)
                        TextSpan(
                          text: '${moduleNumber(first.number)}  ',
                          style: textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
                        ),
                      TextSpan(text: first.module),
                    ],
                  ),
                  style: textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
                ),
                if (level != null)
                  Text(
                    s.level_module_count(level.total),
                    style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
                  ),
                if (!first.ready)
                  Text(s.module_planned, style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          if (_folds) ...[
            const SizedBox(width: AppSpacing.sm),
            // A level's hue is never text: on the card it fell under the 4.5:1 text contrast (review 6, finding 9).
            Text(
              s.catalog_search_matches(_hits.length),
              style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted),
            ),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: still ? Duration.zero : const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, color: colors.onSurfaceMuted),
            ),
          ],
        ],
      ),
    );
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: const BorderRadius.all(BazaarRadii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(color: hue, child: const SizedBox(height: 3)),
          Semantics(
            button: true,
            expanded: _folds ? _open : null,
            child: InkWell(
              // A folding card's head folds and unfolds it; any other card's opens the module or the level.
              onTap: _folds ? () => setState(() => _open = !_open) : () => _go(context, null),
              // At least 48 high, the least a tap target may be.
              child: head,
            ),
          ),
          AnimatedSize(
            duration: still ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.topStart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_folds && !_open)
                  hitRow(_hits.first, folded: true)
                else ...[
                  if (_folds)
                    InkWell(
                      key: ValueKey('catalog-search-open-${first.moduleKey}'),
                      onTap: () => _go(context, null),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.catalog_search_open_module,
                                style: textTheme.labelLarge?.copyWith(color: colors.primary),
                              ),
                            ),
                            Icon(Icons.arrow_forward, size: 18, color: colors.primary),
                          ],
                        ),
                      ),
                    ),
                  for (final hit in _hits) hitRow(hit),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// The excerpt of [hit], its matched words in [mark].
TextSpan _marked(SearchHit hit, TextStyle mark) {
  final text = hit.excerpt;
  var at = 0;
  final spans = <TextSpan>[];
  for (final (start, end) in hit.marks) {
    if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
    spans.add(TextSpan(text: text.substring(start, end), style: mark));
    at = end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(children: spans);
}
