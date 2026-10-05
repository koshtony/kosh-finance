import '../utils/month_utils.dart';
import 'finance_store.dart';

enum InsightTone { positive, warning, neutral }

class Insight {
  final String text;
  final InsightTone tone;
  Insight(this.text, this.tone);
}

String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';
String _money(double v) => v.toStringAsFixed(0);

/// Whole-app dashboard insights: cashflow trend, savings, biggest levers.
List<Insight> dashboardInsights(FinanceStore s) {
  final insights = <Insight>[];
  final periods = s.periodTotals;
  if (periods.isEmpty) return insights;

  final latest = periods.last;
  if (latest.netActual >= 0) {
    insights.add(Insight(
      'Positive net cash flow of KES ${_money(latest.netActual)} in ${latest.label}.',
      InsightTone.positive,
    ));
  } else {
    insights.add(Insight(
      'Negative net cash flow of KES ${_money(-latest.netActual)} in ${latest.label} — expenses outpaced income.',
      InsightTone.warning,
    ));
  }

  // Trend over last 3 periods vs previous 3.
  if (periods.length >= 6) {
    final recent = periods.sublist(periods.length - 3);
    final prior = periods.sublist(periods.length - 6, periods.length - 3);
    final recentAvg = recent.fold<double>(0, (a, p) => a + p.netActual) / 3;
    final priorAvg = prior.fold<double>(0, (a, p) => a + p.netActual) / 3;
    if (recentAvg > priorAvg) {
      insights.add(Insight(
        'Net cash flow is improving: 3-month average rose from KES ${_money(priorAvg)} to KES ${_money(recentAvg)}.',
        InsightTone.positive,
      ));
    } else if (recentAvg < priorAvg) {
      insights.add(Insight(
        'Net cash flow is slipping: 3-month average fell from KES ${_money(priorAvg)} to KES ${_money(recentAvg)}.',
        InsightTone.warning,
      ));
    }
  }

  // Income mix: employment vs business share.
  final totalEmpIncome = periods.fold<double>(0, (a, p) => a + p.empIncomeActual);
  final totalBizIncome = periods.fold<double>(0, (a, p) => a + p.bizRevenueActual);
  final totalIncome = totalEmpIncome + totalBizIncome;
  if (totalIncome > 0) {
    final bizShare = totalBizIncome / totalIncome;
    insights.add(Insight(
      'Business revenue makes up ${_pct(bizShare)} of total actual income since tracking began.',
      InsightTone.neutral,
    ));
  }

  // Investment growth.
  if (s.investments.length >= 2) {
    final first = s.investments.first.closingValue ?? 0;
    final last = s.investments.last.closingValue ?? 0;
    if (first > 0) {
      final growth = (last - first) / first;
      insights.add(Insight(
        growth >= 0
            ? 'Investment portfolio grew ${_pct(growth)} from KES ${_money(first)} to KES ${_money(last)}.'
            : 'Investment portfolio shrank ${_pct(-growth)} from KES ${_money(first)} to KES ${_money(last)}.',
        growth >= 0 ? InsightTone.positive : InsightTone.warning,
      ));
    }
  }

  return insights;
}

/// Employment section insights: variance, largest category, trend.
List<Insight> employmentInsights(FinanceStore s) {
  final insights = <Insight>[];
  final expense = s.employmentExpense;
  final income = s.employmentIncome;
  if (expense.isEmpty && income.isEmpty) return insights;

  final byCategory = <String, double>{};
  for (final e in expense) {
    byCategory[e.item] = (byCategory[e.item] ?? 0) + (e.actual ?? 0);
  }
  if (byCategory.isNotEmpty) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final total = byCategory.values.fold<double>(0, (a, b) => a + b);
    insights.add(Insight(
      '${top.key} is the biggest personal expense category: KES ${_money(top.value)} '
      '(${_pct(top.value / (total == 0 ? 1 : total))} of total spend).',
      InsightTone.neutral,
    ));
  }

  final totalExpected = income.fold<double>(0, (a, e) => a + (e.expected ?? 0));
  final totalActual = income.fold<double>(0, (a, e) => a + (e.actual ?? 0));
  if (totalExpected > 0) {
    final diff = totalActual - totalExpected;
    if (diff >= 0) {
      insights.add(Insight(
        'Income has beaten expectations by KES ${_money(diff)} overall.',
        InsightTone.positive,
      ));
    } else {
      insights.add(Insight(
        'Income is running KES ${_money(-diff)} below expectations overall.',
        InsightTone.warning,
      ));
    }
  }

  final overBudget = <String>[];
  final estByCategory = <String, double>{};
  final actByCategory = <String, double>{};
  for (final e in expense) {
    estByCategory[e.item] = (estByCategory[e.item] ?? 0) + (e.estimated ?? 0);
    actByCategory[e.item] = (actByCategory[e.item] ?? 0) + (e.actual ?? 0);
  }
  for (final key in estByCategory.keys) {
    final est = estByCategory[key] ?? 0;
    final act = actByCategory[key] ?? 0;
    if (est > 0 && act > est * 1.15) overBudget.add(key);
  }
  if (overBudget.isNotEmpty) {
    insights.add(Insight(
      '${overBudget.join(', ')} ${overBudget.length == 1 ? 'is' : 'are'} consistently over budget by 15%+.',
      InsightTone.warning,
    ));
  }

  return insights;
}

/// Business section insights, scoped to one business name.
List<Insight> businessInsights(FinanceStore s, String business) {
  final insights = <Insight>[];
  final revenue = s.businessRevenue.where((r) => r.business == business).toList();
  final expense = s.businessExpense.where((e) => e.business == business).toList();
  if (revenue.isEmpty && expense.isEmpty) return insights;

  final totalRevActual = revenue.fold<double>(0, (a, r) => a + (r.actual ?? 0));
  final totalExpActual = expense.fold<double>(0, (a, e) => a + (e.actual ?? 0));
  final profit = totalRevActual - totalExpActual;
  insights.add(Insight(
    profit >= 0
        ? '$business is profitable overall: KES ${_money(profit)} net since tracking began.'
        : '$business has a net loss of KES ${_money(-profit)} since tracking began.',
    profit >= 0 ? InsightTone.positive : InsightTone.warning,
  ));

  final byCategory = <String, double>{};
  for (final e in expense) {
    byCategory[e.item] = (byCategory[e.item] ?? 0) + (e.actual ?? 0);
  }
  if (byCategory.isNotEmpty) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    insights.add(Insight(
      '${top.key} is the largest cost driver for $business: KES ${_money(top.value)} total.',
      InsightTone.neutral,
    ));
  }

  // Revenue trend: last vs previous period with data.
  final byPeriod = <int, double>{};
  for (final r in revenue) {
    final k = periodKey(r.year, r.month);
    byPeriod[k] = (byPeriod[k] ?? 0) + (r.actual ?? 0);
  }
  final keys = byPeriod.keys.toList()..sort();
  if (keys.length >= 2) {
    final last = byPeriod[keys.last]!;
    final prev = byPeriod[keys[keys.length - 2]]!;
    if (prev > 0) {
      final change = (last - prev) / prev;
      insights.add(Insight(
        change >= 0
            ? 'Revenue rose ${_pct(change)} month-over-month.'
            : 'Revenue dropped ${_pct(-change)} month-over-month.',
        change >= 0 ? InsightTone.positive : InsightTone.warning,
      ));
    }
  }

  return insights;
}

/// Investment section insights: growth, interest trend.
List<Insight> investmentInsights(FinanceStore s) {
  final insights = <Insight>[];
  final inv = s.investments;
  if (inv.isEmpty) return insights;

  final last = inv.last;
  insights.add(Insight(
    'Current portfolio value: KES ${_money(last.closingValue ?? 0)}, '
    'with KES ${_money(last.totalInterest ?? 0)} total interest earned to date.',
    InsightTone.neutral,
  ));

  if (inv.length >= 2) {
    final prev = inv[inv.length - 2];
    final diff = (last.closingValue ?? 0) - (prev.closingValue ?? 0);
    insights.add(Insight(
      diff >= 0
          ? 'Portfolio grew KES ${_money(diff)} since last month.'
          : 'Portfolio shrank KES ${_money(-diff)} since last month — check for withdrawals.',
      diff >= 0 ? InsightTone.positive : InsightTone.warning,
    ));
  }

  final monthlyIncomes = inv.map((e) => e.currentMonthIncome ?? 0).where((v) => v > 0).toList();
  if (monthlyIncomes.isNotEmpty) {
    final avg = monthlyIncomes.fold<double>(0, (a, b) => a + b) / monthlyIncomes.length;
    insights.add(Insight(
      'Average monthly interest income: KES ${_money(avg)}.',
      InsightTone.neutral,
    ));
  }

  return insights;
}

/// Key customers insights: retention, top spenders, target achievement.
List<Insight> customerInsights(FinanceStore s) {
  final insights = <Insight>[];
  if (s.customers.isEmpty) return insights;

  final visited = s.checkins.where((c) => c.status == 'visited').length;
  final missed = s.checkins.where((c) => c.status == 'missed').length;
  final tracked = visited + missed;
  if (tracked > 0) {
    final rate = visited / tracked;
    insights.add(Insight(
      'Customer visit rate is ${_pct(rate)} across tracked weeks ($visited of $tracked).',
      rate >= 0.7 ? InsightTone.positive : InsightTone.warning,
    ));
  }

  final sortedBySpend = [...s.customers]
    ..sort((a, b) => (b.avgSpending ?? 0).compareTo(a.avgSpending ?? 0));
  if (sortedBySpend.isNotEmpty) {
    final top = sortedBySpend.first;
    insights.add(Insight(
      '${top.name} is the highest-value customer at KES ${_money(top.avgSpending ?? 0)} average spend.',
      InsightTone.neutral,
    ));
  }

  final targets = s.revenueTargets.where((t) => t.actual != null && t.target != null);
  if (targets.isNotEmpty) {
    final hitCount = targets.where((t) => (t.actual ?? 0) >= (t.target ?? 0)).length;
    insights.add(Insight(
      'Revenue target was met in $hitCount of ${targets.length} tracked months.',
      hitCount >= targets.length / 2 ? InsightTone.positive : InsightTone.warning,
    ));
  }

  // Customers with no recent activity.
  final customerActivity = <int, bool>{};
  for (final c in s.checkins) {
    if (c.status == 'visited') customerActivity[c.customerId] = true;
  }
  final inactive = s.customers.where((c) => customerActivity[c.id] != true).toList();
  if (inactive.isNotEmpty && inactive.length < s.customers.length) {
    insights.add(Insight(
      '${inactive.length} customer(s) have no recorded visits yet: '
      '${inactive.map((c) => c.name).join(', ')}.',
      InsightTone.warning,
    ));
  }

  return insights;
}
