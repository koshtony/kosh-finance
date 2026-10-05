import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendSeries {
  final String label;
  final Color color;
  final List<double> values;
  TrendSeries(this.label, this.color, this.values);
}

/// A simple multi-series line chart with period labels on the x-axis.
class TrendChart extends StatelessWidget {
  final List<String> periodLabels;
  final List<TrendSeries> series;
  final double height;

  const TrendChart({
    super.key,
    required this.periodLabels,
    required this.series,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (periodLabels.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Not enough data yet')),
      );
    }

    double minY = 0, maxY = 0;
    for (final s in series) {
      for (final v in s.values) {
        if (v < minY) minY = v;
        if (v > maxY) maxY = v;
      }
    }
    final pad = (maxY - minY).abs() * 0.1 + 1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY).abs() / 4).clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (periodLabels.length / 6).ceil().toDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= periodLabels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(periodLabels[i],
                        style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final seriesName = series[s.barIndex].label;
                return LineTooltipItem(
                  '$seriesName\n${s.y.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              }).toList(),
            ),
          ),
          lineBarsData: series.map((s) {
            return LineChartBarData(
              spots: [
                for (int i = 0; i < s.values.length; i++) FlSpot(i.toDouble(), s.values[i])
              ],
              isCurved: true,
              curveSmoothness: 0.2,
              color: s.color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  final List<TrendSeries> series;
  const ChartLegend({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: series
          .map((s) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(s.label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ))
          .toList(),
    );
  }
}
