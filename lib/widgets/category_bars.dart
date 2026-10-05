import 'package:flutter/material.dart';

import '../theme.dart';

/// Horizontal bar breakdown, e.g. expense-by-category. Expects already
/// aggregated (label, value) pairs; renders the top [maxItems] by value.
class CategoryBars extends StatelessWidget {
  final Map<String, double> data;
  final int maxItems;
  final Color color;

  const CategoryBars({
    super.key,
    required this.data,
    this.maxItems = 8,
    this.color = kBrandColor,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(maxItems).toList();
    if (shown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No data yet', style: TextStyle(color: Colors.black45))),
      );
    }
    final maxVal = shown.first.value;

    return Column(
      children: shown.map((e) {
        final frac = maxVal == 0 ? 0.0 : e.value / maxVal;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 14, color: const Color(0xFFF1F5F9)),
                      FractionallySizedBox(
                        widthFactor: frac.clamp(0.02, 1.0),
                        child: Container(height: 14, color: color),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 62,
                child: Text(
                  e.value.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
