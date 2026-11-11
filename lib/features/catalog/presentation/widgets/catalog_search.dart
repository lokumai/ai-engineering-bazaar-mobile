import 'dart:async';

import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search.dart';
import 'package:ai_engineering_bazaar/features/catalog/application/catalog_search_cubit.dart';
import 'package:ai_engineering_bazaar/features/catalog/presentation/catalog_labels.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
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
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    setState(() {});
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
      decoration: InputDecoration(
        hintText: s.catalog_search_hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.close), tooltip: s.catalog_search_clear, onPressed: _clear),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

/// The hits of the catalog's search in place of the levels: how many, then each with its module, its section, and the
/// words around the match, the matched words in bold. A hit opens its module at its section.
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
        for (final (i, hit) in hits.indexed) ...[if (i > 0) const Divider(height: 1), _HitTile(hit: hit, track: track)],
      ],
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.track});

  final SearchHit hit;
  final Track track;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final textTheme = Theme.of(context).textTheme;
    final entry = hit.entry;
    final section = entry.kind == SearchKind.section;
    final module = '${moduleNumber(entry.number)} · ${entry.module}';
    return InkWell(
      onTap: () => context.push(BazaarPaths.module(track, entry.moduleKey), extra: entry.sectionId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section) Text(module, style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted)),
            Text(
              section ? entry.section : module,
              style: textTheme.titleMedium?.copyWith(color: colors.onSurfaceTitle),
            ),
            if (!entry.ready)
              Text(s.module_planned, style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceMuted)),
            if (hit.excerpt.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text.rich(
                _marked(hit, TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
                style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static TextSpan _marked(SearchHit hit, TextStyle mark) {
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
}
