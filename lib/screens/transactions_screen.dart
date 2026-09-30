import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import 'data_refresh_mixin.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with DataRefreshMixin<TransactionsScreen> {
  List<Transaction> _transactions = [];
  String? _filterCategory;
  String? _filterSource;
  bool _loading = true;

  final _fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
  final _dateFmt = DateFormat('MM/dd HH:mm');

  @override
  Future<void> loadData() async {
    final version = ++loadVersion;
    try {
      final db = context.read<DatabaseHelper>();
      final transactions = await db.getTransactions(
        category: _filterCategory,
        source: _filterSource,
      );

      if (mounted && version == loadVersion) {
        setState(() {
          _transactions = transactions;
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

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadData,
            child: _transactions.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('暂无交易记录')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _buildRow(_transactions[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildDropdown<String>(
            value: _filterCategory,
            hint: '全部类别',
            items: Category.defaults.map((c) => c.name).toList(),
            onChanged: (v) {
              setState(() {
                _filterCategory = v;
                _loading = true;
              });
              loadData();
            },
          ),
          const SizedBox(width: 8),
          _buildDropdown<String>(
            value: _filterSource == null
                ? null
                : (_filterSource == 'wechat' ? '微信' : '支付宝'),
            hint: '全部来源',
            items: const ['微信', '支付宝'],
            onChanged: (v) {
              setState(() {
                _filterSource = v == null
                    ? null
                    : (v == '微信' ? 'wechat' : 'alipay');
                _loading = true;
              });
              loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: value as String?,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(hint, style: const TextStyle(color: Colors.grey)),
          ),
          ...items.map(
            (item) => DropdownMenuItem(value: item, child: Text(item)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRow(Transaction t) {
    final cat = Category.defaults.firstWhere(
      (c) => c.name == t.category,
      orElse: () => Category.defaults.last,
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cat.color.withValues(alpha: 0.15),
        child: Icon(cat.icon, color: cat.color, size: 22),
      ),
      title: Text(
        t.merchantName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${t.source == 'wechat' ? '微信' : '支付宝'}  ${_dateFmt.format(t.timestamp)}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Text(
        '${t.isExpense ? '-' : '+'}${_fmt.format(t.amount)}',
        style: TextStyle(
          color: t.isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
