import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_browse.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/scene/shadow_art.dart';
import 'package:ai_engineering_bazaar/features/caravan/presentation/widgets/caravan_period.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Opens every trend in a sheet over the page, searched and filtered by year as the web's list under its scene is
/// (`TrendBrowser.tsx`); the sheet closes on the stop chosen and returns its index, or null.
Future<int?> showTrendListSheet(BuildContext context, {required CaravanRoad road, required int selected}) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) => TrendList(road: road, selected: selected, controller: controller),
      ),
    );

/// The search, the years and the trends that match, each row the trend's goods colour, its name and its period.
class TrendList extends StatefulWidget {
  const TrendList({super.key, required this.road, required this.selected, this.controller});

  final CaravanRoad road;
  final int selected;
  final ScrollController? controller;

  @override
  State<TrendList> createState() => _TrendListState();
}

class _TrendListState extends State<TrendList> {
  int? _year;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final found = filterStops(widget.road, year: _year, query: _query);
    final years = [for (final start in widget.road.yearStarts) start.year];

    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        s.caravan_all_trends,
                        style: displayFace(theme.textTheme.titleLarge)?.copyWith(color: colors.onSurfaceTitle),
                      ),
                    ),
                  ),
                  Text(
                    s.caravan_trend_count(found.length),
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('caravan-search'),
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: s.caravan_search,
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: Text(s.caravan_all_years),
                      selected: _year == null,
                      onSelected: (_) => setState(() => _year = null),
                    ),
                    for (final year in years)
                      ChoiceChip(
                        key: ValueKey('caravan-year-$year'),
                        label: Text('$year'),
                        selected: _year == year,
                        onSelected: (_) => setState(() => _year = _year == year ? null : year),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (found.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: Text(
                s.caravan_no_trend,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceMuted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            sliver: SliverList.builder(
              itemCount: found.length,
              itemBuilder: (context, i) => _TrendRow(
                stop: found[i],
                selected: found[i].index == widget.selected,
                onTap: () => Navigator.of(context).pop(found[i].index),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.stop, required this.selected, required this.onTap});

  final CaravanStop stop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final hue = inkOf(stop.index);
    return Semantics(
      selected: selected,
      child: ListTile(
        key: ValueKey('caravan-trend-${stop.trend.id}'),
        onTap: onTap,
        selected: selected,
        selectedTileColor: colors.primary.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        leading: Container(
          width: 14,
          height: 32,
          decoration: BoxDecoration(
            color: hue,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Color.lerp(hue, Colors.black, 0.3)!),
          ),
        ),
        title: Text(stop.trend.title, style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceTitle)),
        subtitle: Text(
          caravanPeriod(context, stop),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
        ),
        trailing: selected ? Icon(Icons.place, color: colors.primary) : null,
      ),
    );
  }
}
