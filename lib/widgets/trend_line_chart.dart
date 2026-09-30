import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const TrendLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    final totals = <int, double>{};
    for (var i = 0; i < data.length; i++) {
      final monthParts = (data[i]['month'] as String).split('-');
      final monthIndex =
          int.tryParse(monthParts.length > 1 ? monthParts[1] : '0') ?? 0;
      final total = (data[i]['total'] as num).toDouble();
      totals[monthIndex] = total;
    }

    final spots = List.generate(
      12,
      (i) => FlSpot(i.toDouble(), totals[i + 1] ?? 0),
    );
    final peak = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = peak > 0 ? peak * 1.2 : 100.0;

    return LineChart(
      LineChartData(
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
                  '${(value.toInt() + 1)}月',
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
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: const Color(0xFF378ADD),
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF378ADD).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
