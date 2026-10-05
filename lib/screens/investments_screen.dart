import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/finance_store.dart';
import '../services/insights_engine.dart';
import '../theme.dart';
import '../utils/month_utils.dart';
import '../widgets/insight_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/trend_chart.dart';
import 'forms/entry_dialogs.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Investments'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
          ]),
        ),
        body: const TabBarView(children: [
          _InvestmentsOverview(),
          _InvestmentsHistory(),
        ]),
      ),
    );
  }
}

class _InvestmentsOverview extends StatelessWidget {
  const _InvestmentsOverview();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final inv = [...store.investments]
      ..sort((a, b) => periodKey(a.year, a.month).compareTo(periodKey(b.year, b.month)));
    final insights = investmentInsights(store);
    final latest = inv.isEmpty ? null : inv.last;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SummaryGrid(cards: [
          SummaryCard(
            title: 'Current value',
            value: formatMoney(latest?.closingValue ?? 0),
            subtitle: latest == null ? null : shortPeriodLabel(latest.year, latest.month),
            icon: Icons.account_balance_wallet_outlined,
            accentColor: kBrandColor,
          ),
          SummaryCard(
            title: 'Total interest earned',
            value: formatMoney(latest?.totalInterest ?? 0),
            icon: Icons.percent,
            accentColor: kPositiveColor,
          ),
          SummaryCard(
            title: 'Last month\'s income',
            value: formatMoney(latest?.currentMonthIncome ?? 0),
            icon: Icons.attach_money,
          ),
          SummaryCard(
            title: 'Months tracked',
            value: '${inv.length}',
            icon: Icons.timeline,
          ),
        ]),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Portfolio growth', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TrendChart(
                  periodLabels: inv.map((e) => shortPeriodLabel(e.year, e.month)).toList(),
                  series: [
                    TrendSeries('Closing value', kBrandColor,
                        inv.map((e) => e.closingValue ?? 0).toList()),
                  ],
                ),
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

class _InvestmentsHistory extends StatelessWidget {
  const _InvestmentsHistory();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final items = [...store.investments]
      ..sort((a, b) => periodKey(b.year, b.month).compareTo(periodKey(a.year, a.month)));

    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('No investment history yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final e = items[i];
                return Card(
                  child: ListTile(
                    onTap: () => showInvestmentDialog(context, store, existing: e),
                    title: Text(shortPeriodLabel(e.year, e.month)),
                    subtitle: Text('Interest to date: ${formatMoney(e.totalInterest)}'),
                    trailing: Text(formatMoney(e.closingValue),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showInvestmentDialog(context, store),
        child: const Icon(Icons.add),
      ),
    );
  }
}
