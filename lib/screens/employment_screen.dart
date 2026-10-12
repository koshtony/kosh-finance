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

const _kAllSources = 'All sources';

class EmploymentScreen extends StatefulWidget {
  const EmploymentScreen({super.key});

  @override
  State<EmploymentScreen> createState() => _EmploymentScreenState();
}

class _EmploymentScreenState extends State<EmploymentScreen> {
  String _selected = _kAllSources;
  TimeRange _range = TimeRange.allTime;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final sources = [_kAllSources, ...store.distinctIncomeSources];
    if (!sources.contains(_selected)) _selected = _kAllSources;

    void onRangeChanged(TimeRange r) => setState(() => _range = r);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
              items: sources
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v ?? _kAllSources),
            ),
          ),
          bottom: const TabBar(tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ]),
        ),
        body: TabBarView(children: [
          _EmploymentOverview(source: _selected, range: _range, onRangeChanged: onRangeChanged),
          _EmploymentIncomeList(source: _selected, range: _range, onRangeChanged: onRangeChanged),
          _EmploymentExpenseList(range: _range, onRangeChanged: onRangeChanged),
        ]),
      ),
    );
  }
}

class _EmploymentOverview extends StatelessWidget {
  final String source;
  final TimeRange range;
  final ValueChanged<TimeRange> onRangeChanged;
  const _EmploymentOverview({required this.source, required this.range, required this.onRangeChanged});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final insights = employmentInsights(store);

    final income = source == _kAllSources
        ? store.employmentIncome
        : store.employmentIncome.where((e) => e.source == source).toList();
    final filteredIncome = income.where((e) => isPeriodInRange(e.year, e.month, range)).toList();
    final filteredExpense =
        store.employmentExpense.where((e) => isPeriodInRange(e.year, e.month, range)).toList();

    final totalIncome = filteredIncome.fold<double>(0, (a, e) => a + (e.actual ?? 0));
    final totalExpense = filteredExpense.fold<double>(0, (a, e) => a + (e.actual ?? 0));

    final byPeriod = <int, Map<String, double>>{};
    for (final e in filteredIncome) {
      final k = periodKey(e.year, e.month);
      byPeriod.putIfAbsent(k, () => {'inc': 0, 'exp': 0});
      byPeriod[k]!['inc'] = byPeriod[k]!['inc']! + (e.actual ?? 0);
    }
    for (final e in filteredExpense) {
      final k = periodKey(e.year, e.month);
      byPeriod.putIfAbsent(k, () => {'inc': 0, 'exp': 0});
      byPeriod[k]!['exp'] = byPeriod[k]!['exp']! + (e.actual ?? 0);
    }
    final keys = byPeriod.keys.toList()..sort();
    final labels = keys.map((k) {
      final month = monthOrder[k % 12];
      final year = (k / 12).floor();
      return shortPeriodLabel(year, month);
    }).toList();

    final byCategory = <String, double>{};
    for (final e in filteredExpense) {
      byCategory[e.item] = (byCategory[e.item] ?? 0) + (e.actual ?? 0);
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        TimeRangeSelector(selected: range, onChanged: onRangeChanged),
        const SizedBox(height: 10),
        SummaryGrid(cards: [
          SummaryCard(
            title: 'Income (${range.label.toLowerCase()})',
            value: formatMoney(totalIncome),
            icon: Icons.payments_outlined,
            accentColor: kPositiveColor,
          ),
          SummaryCard(
            title: 'Personal expenses (${range.label.toLowerCase()})',
            value: formatMoney(totalExpense),
            icon: Icons.receipt_long_outlined,
            accentColor: kWarningColor,
          ),
          SummaryCard(
            title: 'Net savings (${range.label.toLowerCase()})',
            value: formatMoney(totalIncome - totalExpense),
            icon: Icons.savings_outlined,
            accentColor: (totalIncome - totalExpense) >= 0 ? kPositiveColor : kWarningColor,
          ),
          SummaryCard(
            title: 'Months tracked',
            value: '${byPeriod.length}',
            icon: Icons.calendar_month_outlined,
          ),
        ]),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Income vs expense (${range.label.toLowerCase()})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TrendChart(
                  periodLabels: labels,
                  series: [
                    TrendSeries('Income', kPositiveColor, keys.map((k) => byPeriod[k]!['inc']!).toList()),
                    TrendSeries('Expense', kWarningColor, keys.map((k) => byPeriod[k]!['exp']!).toList()),
                  ],
                ),
                const SizedBox(height: 8),
                ChartLegend(series: [
                  TrendSeries('Income', kPositiveColor, []),
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
                Text('Spending by category (${range.label.toLowerCase()})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _EmploymentIncomeList extends StatelessWidget {
  final String source;
  final TimeRange range;
  final ValueChanged<TimeRange> onRangeChanged;
  const _EmploymentIncomeList({required this.source, required this.range, required this.onRangeChanged});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final items = (source == _kAllSources
        ? [...store.employmentIncome]
        : store.employmentIncome.where((e) => e.source == source).toList())
        .where((e) => isPeriodInRange(e.year, e.month, range))
        .toList()
      ..sort((a, b) => periodKey(b.year, b.month).compareTo(periodKey(a.year, a.month)));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: TimeRangeSelector(selected: range, onChanged: onRangeChanged),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No income recorded in this period'))
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final e = items[i];
                      final diff = (e.actual ?? 0) - (e.expected ?? 0);
                      return Card(
                        child: ListTile(
                          onTap: () => showEmploymentIncomeDialog(context, store, existing: e),
                          title: Text(e.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${e.source} · ${shortPeriodLabel(e.year, e.month)} · expected ${formatMoney(e.expected)}'),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEmploymentIncomeDialog(
          context, store,
          defaultSource: source == _kAllSources ? null : source,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmploymentExpenseList extends StatelessWidget {
  final TimeRange range;
  final ValueChanged<TimeRange> onRangeChanged;
  const _EmploymentExpenseList({required this.range, required this.onRangeChanged});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final items = store.employmentExpense
        .where((e) => isPeriodInRange(e.year, e.month, range))
        .toList()
      ..sort((a, b) => periodKey(b.year, b.month).compareTo(periodKey(a.year, a.month)));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: TimeRangeSelector(selected: range, onChanged: onRangeChanged),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No expenses recorded in this period'))
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final e = items[i];
                      final over = (e.actual ?? 0) > (e.estimated ?? 0);
                      return Card(
                        child: ListTile(
                          onTap: () => showEmploymentExpenseDialog(context, store, existing: e),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEmploymentExpenseDialog(context, store),
        child: const Icon(Icons.add),
      ),
    );
  }
}
