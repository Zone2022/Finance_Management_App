import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int year;

  const MonthlyBarChart({super.key, required this.data, required this.year});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    final map = <int, double>{};
    for (final row in data) {
      final parts = (row['month'] as String).split('-');
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      map[m] = (row['total'] as num).toDouble();
    }

    final peak = map.values.fold(0.0, (a, b) => a > b ? a : b);
    final maxY = peak > 0 ? peak * 1.2 : 100.0;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}月',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        barGroups: List.generate(12, (i) {
          final value = map[i + 1] ?? 0.0;
          return BarChartGroupData(
            x: i + 1,
            barRods: [
              BarChartRodData(
                toY: value,
                color: value > 0
                    ? const Color(0xFF378ADD)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
