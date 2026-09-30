import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import 'data_refresh_mixin.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/trend_line_chart.dart';
import '../widgets/monthly_bar_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with DataRefreshMixin<ReportsScreen> {
  Map<String, double> _categoryData = {};
  List<Map<String, dynamic>> _monthlyData = [];
  bool _loading = true;
  int _selectedYear = DateTime.now().year;

  @override
  Future<void> loadData() async {
    final version = ++loadVersion;
    try {
      final db = context.read<DatabaseHelper>();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1);

      final results = await Future.wait([
        db.getExpenseByCategory(startDate: monthStart, endDate: monthEnd),
        db.getMonthlyExpense(_selectedYear),
      ]);

      if (mounted && version == loadVersion) {
        setState(() {
          _categoryData = results[0] as Map<String, double>;
          _monthlyData = results[1] as List<Map<String, dynamic>>;
          _loading = false;
          loadError = null;
        });
      }
    } catch (_) {
      if (mounted && version == loadVersion) {
        setState(() {
          _loading = false;
          loadError = '数据加载失败，请重试';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadError != null) return errorView();
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '本月支出分类',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: ExpensePieChart(data: _categoryData)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '月度支出趋势',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(
                  5,
                  (i) => DropdownMenuItem(
                    value: DateTime.now().year - i,
                    child: Text('${DateTime.now().year - i}'),
                  ),
                ),
                onChanged: (year) {
                  setState(() {
                    _selectedYear = year!;
                    _loading = true;
                  });
                  loadData();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: MonthlyBarChart(data: _monthlyData, year: _selectedYear),
          ),
          const SizedBox(height: 24),
          const Text(
            '年度趋势',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: TrendLineChart(data: _monthlyData)),
        ],
      ),
    );
  }
}
