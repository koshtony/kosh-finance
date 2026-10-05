const List<String> monthOrder = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

int monthIndex(String month) {
  final i = monthOrder.indexOf(month);
  return i == -1 ? 0 : i;
}

/// A sortable key combining year and month so Nov 2025 < Jan 2026.
int periodKey(int year, String month) => year * 12 + monthIndex(month);

String periodLabel(int year, String month) => '$month $year';

/// Returns the short year-aware label, e.g. "Nov'25".
String shortPeriodLabel(int year, String month) =>
    "$month'${year.toString().substring(2)}";
