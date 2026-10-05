import 'month_utils.dart';

enum TimeRange { allTime, thisYear, thisMonth }

extension TimeRangeLabel on TimeRange {
  String get label => switch (this) {
        TimeRange.allTime => 'All time',
        TimeRange.thisYear => 'This year',
        TimeRange.thisMonth => 'This month',
      };
}

/// Whether a (year, month) budget entry falls inside [range].
bool isPeriodInRange(int year, String month, TimeRange range) {
  final now = DateTime.now();
  switch (range) {
    case TimeRange.allTime:
      return true;
    case TimeRange.thisYear:
      return year == now.year;
    case TimeRange.thisMonth:
      return year == now.year && month == monthOrder[now.month - 1];
  }
}
