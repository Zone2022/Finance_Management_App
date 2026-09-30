import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';

class ExpensePieChart extends StatelessWidget {
  final Map<String, double> data;

  const ExpensePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final positiveData = Map.fromEntries(
      data.entries.where((e) => e.value.isFinite && e.value > 0),
    );
    if (positiveData.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    final total = positiveData.values.fold(0.0, (a, b) => a + b);

    return PieChart(
      PieChartData(
        sections: positiveData.entries.map((entry) {
          final cat = Category.defaults.firstWhere(
            (c) => c.name == entry.key,
            orElse: () => Category.defaults.last,
          );
          final pct = (entry.value / total * 100).toStringAsFixed(1);
          return PieChartSectionData(
            color: cat.color,
            value: entry.value,
            title: '$pct%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            radius: 65,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 45,
      ),
    );
  }
}
