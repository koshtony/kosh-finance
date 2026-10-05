import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/finance_store.dart';
import '../services/insights_engine.dart';
import '../theme.dart';
import '../utils/month_utils.dart';
import '../utils/time_range.dart';
import '../widgets/category_bars.dart';
import '../widgets/insight_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/trend_chart.dart';
import 'forms/entry_dialogs.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final businesses = store.distinctBusinesses;
    _selected ??= businesses.isNotEmpty ? businesses.first : null;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
              items: businesses
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
          ),
          bottom: const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Revenue'),
            Tab(text: 'Expenses'),
            Tab(text: 'Daily sales'),
          ]),
        ),
        body: _selected == null
            ? const Center(child: Text('No businesses yet'))
            : TabBarView(children: [
                _BusinessOverview(business: _selected!),
                _BusinessRevenueList(business: _selected!),
                _BusinessExpenseList(business: _selected!),
                _BusinessDailySalesTab(business: _selected!),
              ]),
      ),
    );
  }
}

class _BusinessOverview extends StatefulWidget {
  final String business;
  const _BusinessOverview({required this.business});

  @override
  State<_BusinessOverview> createState() => _BusinessOverviewState();
}

class _BusinessOverviewState extends State<_BusinessOverview> {
  TimeRange _range = TimeRange.allTime;

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final store = context.watch<FinanceStore>();
    final revenue = store.businessRevenue.where((r) => r.business == business).toList();
    final expense = store.businessExpense.where((e) => e.business == business).toList();
    final insights = businessInsights(store, business);

    final filteredRevenue = revenue.where((r) => isPeriodInRange(r.year, r.month, _range)).toList();
    final filteredExpense = expense.where((e) => isPeriodInRange(e.year, e.month, _range)).toList();
    final totalRevenue = filteredRevenue.fold<double>(0, (a, r) => a + (r.actual ?? 0));
    final totalExpense = filteredExpense.fold<double>(0, (a, e) => a + (e.actual ?? 0));

    final byPeriod = <int, Map<String, double>>{};
    for (final r in revenue) {
      final k = periodKey(r.year, r.month);
      byPeriod.putIfAbsent(k, () => {'rev': 0, 'exp': 0, 'y': r.year.toDouble()});
      byPeriod[k]!['rev'] = byPeriod[k]!['rev']! + (r.actual ?? 0);
    }
    for (final e in expense) {
      final k = periodKey(e.year, e.month);
      byPeriod.putIfAbsent(k, () => {'rev': 0, 'exp': 0, 'y': e.year.toDouble()});
      byPeriod[k]!['exp'] = byPeriod[k]!['exp']! + (e.actual ?? 0);
    }
    final keys = byPeriod.keys.toList()..sort();
    final labels = keys.map((k) {
      final month = monthOrder[k % 12];
      final year = (k / 12).floor();
      return shortPeriodLabel(year, month);
    }).toList();

    final byCategory = <String, double>{};
    for (final e in expense) {
      byCategory[e.item] = (byCategory[e.item] ?? 0) + (e.actual ?? 0);
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        TimeRangeSelector(selected: _range, onChanged: (r) => setState(() => _range = r)),
        const SizedBox(height: 10),
        SummaryGrid(cards: [
          SummaryCard(
            title: 'Revenue (${_range.label.toLowerCase()})',
            value: formatMoney(totalRevenue),
            icon: Icons.point_of_sale_outlined,
            accentColor: kPositiveColor,
          ),
          SummaryCard(
            title: 'Expenses (${_range.label.toLowerCase()})',
            value: formatMoney(totalExpense),
            icon: Icons.receipt_long_outlined,
            accentColor: kWarningColor,
          ),
          SummaryCard(
            title: 'Net profit (${_range.label.toLowerCase()})',
            value: formatMoney(totalRevenue - totalExpense),
            icon: Icons.account_balance_outlined,
            accentColor: (totalRevenue - totalExpense) >= 0 ? kPositiveColor : kWarningColor,
          ),
          SummaryCard(
            title: 'Margin (${_range.label.toLowerCase()})',
            value: totalRevenue == 0
                ? '—'
                : '${(((totalRevenue - totalExpense) / totalRevenue) * 100).toStringAsFixed(0)}%',
            icon: Icons.percent,
          ),
        ]),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue vs expense (full history)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TrendChart(
                  periodLabels: labels,
                  series: [
                    TrendSeries('Revenue', kPositiveColor, keys.map((k) => byPeriod[k]!['rev']!).toList()),
                    TrendSeries('Expense', kWarningColor, keys.map((k) => byPeriod[k]!['exp']!).toList()),
                  ],
                ),
                const SizedBox(height: 8),
                ChartLegend(series: [
                  TrendSeries('Revenue', kPositiveColor, []),
                  TrendSeries('Expense', kWarningColor, []),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cost breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                CategoryBars(data: byCategory, color: kBrandColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        InsightsPanel(insights: insights),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BusinessRevenueList extends StatelessWidget {
  final String business;
  const _BusinessRevenueList({required this.business});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final items = store.businessRevenue.where((r) => r.business == business).toList()
      ..sort((a, b) => periodKey(b.year, b.month).compareTo(periodKey(a.year, a.month)));

    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('No revenue recorded yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final e = items[i];
                final diff = (e.actual ?? 0) - (e.expected ?? 0);
                return Card(
                  child: ListTile(
                    onTap: () => showBusinessRevenueDialog(context, store, existing: e),
                    title: Text(shortPeriodLabel(e.year, e.month)),
                    subtitle: Text('Expected ${formatMoney(e.expected)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatMoney(e.actual), style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          diff >= 0 ? '+${diff.toStringAsFixed(0)}' : diff.toStringAsFixed(0),
                          style: TextStyle(fontSize: 11, color: diff >= 0 ? kPositiveColor : kWarningColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBusinessRevenueDialog(context, store, defaultBusiness: business),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BusinessExpenseList extends StatelessWidget {
  final String business;
  const _BusinessExpenseList({required this.business});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final items = store.businessExpense.where((e) => e.business == business).toList()
      ..sort((a, b) => periodKey(b.year, b.month).compareTo(periodKey(a.year, a.month)));

    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('No expenses recorded yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final e = items[i];
                final over = (e.actual ?? 0) > (e.estimated ?? 0);
                return Card(
                  child: ListTile(
                    onTap: () => showBusinessExpenseDialog(context, store, existing: e),
                    title: Text(e.item, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${shortPeriodLabel(e.year, e.month)} · budget ${formatMoney(e.estimated)}'),
                    trailing: Text(
                      formatMoney(e.actual),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: over ? kWarningColor : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBusinessExpenseDialog(context, store, defaultBusiness: business),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BusinessDailySalesTab extends StatelessWidget {
  final String business;
  const _BusinessDailySalesTab({required this.business});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final sales = store.dailySalesFor(business);

    final today = DateTime.now();
    final todayIso = formatIsoDate(today);
    final weekStart = formatIsoDate(today.subtract(Duration(days: today.weekday - 1)));
    final monthStart = formatIsoDate(DateTime(today.year, today.month, 1));

    final todayTotal = sales.where((s) => s.date == todayIso).fold<double>(0, (a, s) => a + s.amount);
    final weekTotal = store.dailySalesTotalFor(business, since: weekStart);
    final monthTotal = store.dailySalesTotalFor(business, since: monthStart);
    final monthDaysWithSales = sales.where((s) => s.date.compareTo(monthStart) >= 0).map((s) => s.date).toSet().length;
    final dailyAverage = monthDaysWithSales == 0 ? 0.0 : monthTotal / monthDaysWithSales;

    String? bestDay;
    double bestDayTotal = 0;
    final byDate = <String, double>{};
    for (final s in sales) {
      byDate[s.date] = (byDate[s.date] ?? 0) + s.amount;
    }
    byDate.forEach((date, total) {
      if (total > bestDayTotal) {
        bestDayTotal = total;
        bestDay = date;
      }
    });

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SummaryGrid(cards: [
            SummaryCard(
              title: 'Today',
              value: formatMoney(todayTotal),
              icon: Icons.today_outlined,
              accentColor: kPositiveColor,
            ),
            SummaryCard(
              title: 'This week',
              value: formatMoney(weekTotal),
              icon: Icons.date_range_outlined,
            ),
            SummaryCard(
              title: 'This month',
              value: formatMoney(monthTotal),
              icon: Icons.calendar_month_outlined,
              accentColor: kBrandColor,
            ),
            SummaryCard(
              title: 'Daily average (this month)',
              value: formatMoney(dailyAverage),
              icon: Icons.insights_outlined,
            ),
          ]),
          if (bestDay != null) ...[
            const SizedBox(height: 14),
            InsightsPanel(insights: [
              Insight(
                'Best day so far: $bestDay with ${formatMoney(bestDayTotal)} in sales.',
                InsightTone.positive,
              ),
              if (sales.isEmpty)
                Insight('No daily sales logged yet for $business — tap + to add today\'s.', InsightTone.neutral),
            ]),
          ],
          const SizedBox(height: 14),
          const Text('Recent entries', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (sales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No daily sales recorded yet', style: TextStyle(color: Colors.black45))),
            )
          else
            ...sales.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      onTap: () => showDailySaleDialog(context, store, existing: s),
                      title: Text(formatMoney(s.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(s.note == null ? s.date : '${s.date} · ${s.note}'),
                    ),
                  ),
                )),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDailySaleDialog(context, store, defaultBusiness: business),
        child: const Icon(Icons.add),
      ),
    );
  }
}
