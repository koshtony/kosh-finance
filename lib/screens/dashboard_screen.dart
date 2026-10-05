import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/finance_store.dart';
import '../services/insights_engine.dart';
import '../theme.dart';
import '../utils/time_range.dart';
import '../widgets/bee_branding.dart';
import '../widgets/insight_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/trend_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TimeRange _range = TimeRange.allTime;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final periods = store.periodTotals;
    final latest = store.latestPeriod;
    final insights = dashboardInsights(store);

    final filtered = periods.where((p) => isPeriodInRange(p.year, p.month, _range)).toList();
    final totalIncome = filtered.fold<double>(0, (a, p) => a + p.totalIncomeActual);
    final totalExpense = filtered.fold<double>(0, (a, p) => a + p.totalExpenseActual);
    final netFlow = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            BeeLogo(size: 28),
            SizedBox(width: 8),
            Text('Kosh Finance'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: store.load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(
              latest != null ? 'As of ${latest.label}' : 'Overview',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TimeRangeSelector(selected: _range, onChanged: (r) => setState(() => _range = r)),
            const SizedBox(height: 10),
            SummaryGrid(cards: [
              SummaryCard(
                title: 'Net worth (cash + investments)',
                value: formatMoney(store.netWorthProxy),
                icon: Icons.account_balance_wallet_outlined,
                accentColor: kBrandColor,
              ),
              SummaryCard(
                title: 'Net flow (${_range.label.toLowerCase()})',
                value: formatMoney(netFlow),
                icon: Icons.swap_vert,
                accentColor: netFlow >= 0 ? kPositiveColor : kWarningColor,
              ),
              SummaryCard(
                title: 'Total income (${_range.label.toLowerCase()})',
                value: formatMoney(totalIncome),
                icon: Icons.arrow_downward,
                accentColor: kPositiveColor,
              ),
              SummaryCard(
                title: 'Total expense (${_range.label.toLowerCase()})',
                value: formatMoney(totalExpense),
                icon: Icons.arrow_upward,
                accentColor: kWarningColor,
              ),
            ]),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Income vs expense trend (full history)',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TrendChart(
                      periodLabels: periods.map((p) => p.label).toList(),
                      series: [
                        TrendSeries('Income', kPositiveColor,
                            periods.map((p) => p.totalIncomeActual).toList()),
                        TrendSeries('Expense', kWarningColor,
                            periods.map((p) => p.totalExpenseActual).toList()),
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
            const Text(
              'Overall net worth is cash flow plus the current investment '
              'balance — a quick read on whether things are moving in the right direction.',
              style: TextStyle(color: Colors.black45, fontSize: 11),
            ),
            const SizedBox(height: 14),
            InsightsPanel(insights: insights),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
