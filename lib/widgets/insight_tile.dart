import 'package:flutter/material.dart';

import '../services/insights_engine.dart';
import '../theme.dart';

class InsightsPanel extends StatelessWidget {
  final List<Insight> insights;
  const InsightsPanel({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: kBrandColor),
                SizedBox(width: 6),
                Text('Insights',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            ...insights.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: _InsightRow(insight: i),
                )),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final Insight insight;
  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (insight.tone) {
      InsightTone.positive => (kPositiveColor, Icons.trending_up),
      InsightTone.warning => (kWarningColor, Icons.warning_amber_rounded),
      InsightTone.neutral => (kNeutralColor, Icons.info_outline),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            insight.text,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }
}
