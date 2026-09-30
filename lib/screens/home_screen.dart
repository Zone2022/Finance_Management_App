import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import 'data_refresh_mixin.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onViewTransactions;
  const HomeScreen({super.key, required this.onViewTransactions});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with DataRefreshMixin<HomeScreen> {
  double _monthlyTotal = 0;
  double _dailyAvg = 0;
  int _transactionCount = 0;
  bool _loading = true;

  @override
  Future<void> loadData() async {
    final version = ++loadVersion;
    try {
      final db = context.read<DatabaseHelper>();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1);

      final results = await Future.wait([
        db.getTotalExpense(startDate: monthStart, endDate: monthEnd),
        db.getDailyAverage(
          startDate: monthStart,
          endDate: DateTime(now.year, now.month, now.day + 1),
        ),
        db.getTransactions(startDate: monthStart, endDate: monthEnd),
      ]);

      if (mounted && version == loadVersion) {
        setState(() {
          _monthlyTotal = results[0] as double;
          _dailyAvg = results[1] as double;
          _transactionCount = (results[2] as List).length;
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
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 2);

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
            '本月概览',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: '本月支出',
                  value: fmt.format(_monthlyTotal),
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: '日均支出',
                  value: fmt.format(_dailyAvg),
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: '交易笔数',
            value: '$_transactionCount 笔',
            icon: Icons.receipt_long,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            '快捷入口',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _QuickAction(
            icon: Icons.receipt,
            label: '查看全部流水',
            onTap: widget.onViewTransactions,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
