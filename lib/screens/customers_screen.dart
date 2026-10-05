import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/finance_store.dart';
import '../services/insights_engine.dart';
import '../theme.dart';
import '../utils/month_utils.dart';
import '../widgets/insight_tile.dart';
import '../widgets/summary_card.dart';
import 'forms/entry_dialogs.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Key Customers'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Weekly check-ins'),
          ]),
        ),
        body: const TabBarView(children: [
          _CustomersOverview(),
          _CheckinGrid(),
        ]),
      ),
    );
  }
}

class _CustomersOverview extends StatelessWidget {
  const _CustomersOverview();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final insights = customerInsights(store);

    final visited = store.checkins.where((c) => c.status == 'visited').length;
    final missed = store.checkins.where((c) => c.status == 'missed').length;
    final tracked = visited + missed;
    final rate = tracked == 0 ? 0.0 : visited / tracked;

    final targets = [...store.revenueTargets];
    final hitCount = targets.where((t) => (t.actual ?? -1) >= (t.target ?? 0)).length;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SummaryGrid(cards: [
          SummaryCard(
            title: 'Customers tracked',
            value: '${store.customers.length}',
            icon: Icons.groups_outlined,
            accentColor: kBrandColor,
          ),
          SummaryCard(
            title: 'Visit rate',
            value: '${(rate * 100).toStringAsFixed(0)}%',
            subtitle: '$visited of $tracked weeks',
            icon: Icons.check_circle_outline,
            accentColor: rate >= 0.7 ? kPositiveColor : kWarningColor,
          ),
          SummaryCard(
            title: 'Targets met',
            value: '$hitCount / ${targets.length}',
            icon: Icons.flag_outlined,
          ),
          SummaryCard(
            title: 'Avg. spend / customer',
            value: formatMoney(store.customers.isEmpty
                ? 0
                : store.customers.fold<double>(0, (a, c) => a + (c.avgSpending ?? 0)) /
                    store.customers.length),
            icon: Icons.sell_outlined,
          ),
        ]),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Revenue target vs actual', style: TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _showTargetDialog(context, store),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (targets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('No targets yet', style: TextStyle(color: Colors.black45))),
                  )
                else
                  ...targets.map((t) => _TargetRow(target: t, store: store)),
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

class _TargetRow extends StatelessWidget {
  final RevenueTarget target;
  final FinanceStore store;
  const _TargetRow({required this.target, required this.store});

  @override
  Widget build(BuildContext context) {
    final t = target.target ?? 0;
    final a = target.actual;
    final frac = (t == 0 || a == null) ? 0.0 : (a / t).clamp(0.0, 1.5);
    final met = a != null && a >= t;
    return InkWell(
      onTap: () => _showTargetDialog(context, store, existing: target),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 50, child: Text(target.month, style: const TextStyle(fontSize: 12))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(height: 12, color: const Color(0xFFF1F5F9)),
                  FractionallySizedBox(
                    widthFactor: frac.clamp(0.02, 1.0),
                    child: Container(height: 12, color: met ? kPositiveColor : kWarningColor),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text(
                a == null ? 'target ${t.toStringAsFixed(0)}' : '${a.toStringAsFixed(0)} / ${t.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showTargetDialog(BuildContext context, FinanceStore store, {RevenueTarget? existing}) {
  String month = existing?.month ?? monthOrder[DateTime.now().month - 1];
  double? target = existing?.target;
  double? actual = existing?.actual;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null ? 'Add target' : 'Edit target'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: month,
                decoration: const InputDecoration(labelText: 'Month'),
                items: monthOrder.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => month = v ?? month),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextFormField(
                  initialValue: target?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Target'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => target = double.tryParse(v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextFormField(
                  initialValue: actual?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Actual'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => actual = double.tryParse(v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await store.deleteRevenueTarget(existing.id!);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final entry = RevenueTarget(id: existing?.id, month: month, target: target, actual: actual);
              if (existing == null) {
                await store.addRevenueTarget(entry);
              } else {
                await store.updateRevenueTarget(entry);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class _CheckinGrid extends StatefulWidget {
  const _CheckinGrid();

  @override
  State<_CheckinGrid> createState() => _CheckinGridState();
}

class _CheckinGridState extends State<_CheckinGrid> {
  String? _month;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final months = {...store.checkins.map((c) => c.month)}.toList()
      ..sort((a, b) => monthIndex(a).compareTo(monthIndex(b)));
    _month ??= months.isNotEmpty ? months.last : monthOrder[DateTime.now().month - 1];
    if (!months.contains(_month) && months.isNotEmpty) _month = months.last;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('Month:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _month,
                  items: monthOrder
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _month = v),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => showCustomerDialog(context, store),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Add customer'),
                ),
              ],
            ),
          ),
          Expanded(
            child: store.customers.isEmpty
                ? const Center(child: Text('No customers yet'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: store.customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final c = store.customers[i];
                      return _CustomerCheckinCard(customer: c, month: _month!);
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CustomerCheckinCard extends StatelessWidget {
  final Customer customer;
  final String month;
  const _CustomerCheckinCard({required this.customer, required this.month});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final weekStatus = <int, String?>{};
    for (final chk in store.checkins) {
      if (chk.customerId == customer.id && chk.month == month) {
        weekStatus[chk.week] = chk.status;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => showCustomerDialog(context, store, existing: customer),
                    child: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  if (customer.category != null)
                    Text(customer.category!, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  if (customer.avgSpending != null)
                    Text('avg ${formatMoney(customer.avgSpending)}',
                        style: const TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),
            ...List.generate(4, (i) {
              final week = i + 1;
              final status = weekStatus[week];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () {
                    final next = switch (status) {
                      null => 'visited',
                      'visited' => 'missed',
                      _ => null,
                    };
                    store.setCheckin(customer.id!, month, week, next);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: switch (status) {
                        'visited' => kPositiveColor.withValues(alpha: 0.15),
                        'missed' => kWarningColor.withValues(alpha: 0.15),
                        _ => const Color(0xFFF1F5F9),
                      },
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      switch (status) {
                        'visited' => '✓',
                        'missed' => '✗',
                        _ => 'W$week',
                      },
                      style: TextStyle(
                        fontSize: status == null ? 9 : 14,
                        fontWeight: FontWeight.w700,
                        color: switch (status) {
                          'visited' => kPositiveColor,
                          'missed' => kWarningColor,
                          _ => Colors.black38,
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
