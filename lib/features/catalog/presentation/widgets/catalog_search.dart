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

/// The hits of the catalog's search in place of the levels (plan 7.1): how many, then one card per module, in the order
/// of its best hit, under its level's hue, with the module's name and each matching section under it, its heading and
/// the words around the match, the matched words in bold. A section opens its module at that section, the module's name
/// at its top; either way the words searched are marked in the module.
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
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Semantics(
          liveRegion: true,
          child: Text(s.catalog_search_none(state.query.trim()), style: textTheme.bodyLarge?.copyWith(color: muted)),
        ),
      );
    }
    final groups = <String, List<SearchHit>>{};
    for (final hit in hits) {
      (groups[hit.entry.moduleKey] ??= []).add(hit);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        for (final group in groups.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ModuleHits(hits: group, track: track, query: state.query),
          ),
      ],
    );
  }
}

/// One module's hits in a card, the level's hue across its top.
class _ModuleHits extends StatelessWidget {
  const _ModuleHits({required this.hits, required this.track, required this.query});

  final List<SearchHit> hits;
  final Track track;
  final String query;

  bool get _level => hits.first.entry.kind == SearchKind.level;

  /// Opens the module at [fragment] with the words searched marked, or the level's page for a level.
  void _open(BuildContext context, String? fragment) => _level
      ? context.push(BazaarPaths.level(track, hits.first.entry.moduleKey))
      : context.push(
          BazaarPaths.module(track, hits.first.entry.moduleKey),
          extra: ReaderTarget(fragment: fragment, query: query),
        );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final first = hits.first.entry;
    final index = (context.read<ContentBloc>().state as ContentReady).index;
    final level = _level ? index.level(first.moduleKey) : null;
    final hue = levelHue(context, levelPosition(index, first.moduleKey.split('/').first));
    final mark = TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface);
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
          InkWell(
            onTap: () => _open(context, null),
            // At least 48 high, the least a tap target may be.
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
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
          ),
          for (final hit in hits)
            InkWell(
              onTap: () => _open(context, hit.entry.sectionId),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
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
