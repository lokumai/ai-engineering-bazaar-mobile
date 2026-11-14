import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// When [stop]'s trend was on the road, as "Nov 2022 to Feb 2023" in the app's language, or "Jul 2026 to now" for a
/// trend people still call new.
String caravanPeriod(BuildContext context, CaravanStop stop) {
  final s = S.of(context);
  final format = DateFormat.yMMM(Localizations.localeOf(context).languageCode);
  final start = format.format(stop.trend.start);
  final end = stop.trend.end;
  return end == null ? s.caravan_period_open(start) : s.caravan_period(start, format.format(end));
}
