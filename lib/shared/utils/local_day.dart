/// The reader's own day, which Home's card of the day and Practice's review of the day both turn on at local midnight.
library;

/// The day [now] falls on, counted from 1970-01-01 in the reader's own calendar: it turns at local midnight. A UTC
/// moment is read in the local zone first.
int dayNumber(DateTime now) {
  final local = now.toLocal();
  return DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// How long from [now] until a moment past the next local midnight. A UTC moment is read in the local zone first, so
/// the wait is never below zero: east of UTC, a UTC moment's own date can be the day before the local one.
Duration untilLocalMidnight(DateTime now) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day + 1).difference(local) + const Duration(seconds: 1);
}
