import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class TransactionEditor extends StatefulWidget {
  const TransactionEditor({super.key, this.transaction});
  final Transaction? transaction;
  @override
  State<TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends State<TransactionEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController amount;
  late final TextEditingController merchant;
  late final TextEditingController note;
  late String category;
  late String source;
  late bool expense;
  late DateTime date;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    amount = TextEditingController(text: t?.amount.toStringAsFixed(2) ?? '');
    merchant = TextEditingController(text: t?.merchantName ?? '');
    note = TextEditingController(text: t?.note ?? '');
    category = Category.defaults.any((c) => c.name == t?.category)
        ? t!.category
        : '其他';
    source = ['wechat', 'alipay', 'bank', 'manual'].contains(t?.source)
        ? t!.source
        : 'manual';
    expense = t?.isExpense ?? true;
    date = t?.timestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    amount.dispose();
    merchant.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || saving) return;
    setState(() => saving = true);
    final old = widget.transaction;
    final t = Transaction(
      id: old?.id,
      amount: double.parse(amount.text.trim()),
      merchantName: merchant.text.trim(),
      category: category,
      source: source,
      timestamp: date,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
      eventId: old?.eventId,
      isExpense: expense,
    );
    try {
      final db = context.read<DatabaseHelper>();
      if (old == null) {
        await db.insertTransaction(t);
      } else {
        if (await db.updateTransaction(t) != 1) throw StateError('交易不存在');
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.transaction == null ? '新增交易' : '编辑交易')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '金额（元）'),
            validator: (v) {
              final s = (v ?? '').trim();
              final n = double.tryParse(s);
              if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(s) ||
                  n == null ||
                  n <= 0) {
                return '请输入大于零的金额，最多两位小数';
              }
              return null;
            },
          ),
          TextFormField(
            controller: merchant,
            decoration: const InputDecoration(labelText: '商户或用途'),
            validator: (v) => (v ?? '').trim().isEmpty ? '请输入商户或用途' : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: '分类'),
            items: Category.defaults
                .map(
                  (c) => DropdownMenuItem(value: c.name, child: Text(c.name)),
                )
                .toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
          DropdownButtonFormField<String>(
            initialValue: source,
            decoration: const InputDecoration(labelText: '来源'),
            items: const [
              DropdownMenuItem(value: 'manual', child: Text('手动')),
              DropdownMenuItem(value: 'wechat', child: Text('微信')),
              DropdownMenuItem(value: 'alipay', child: Text('支付宝')),
              DropdownMenuItem(value: 'bank', child: Text('建设银行')),
            ],
            onChanged: (v) => setState(() => source = v!),
          ),
          SwitchListTile(
            title: const Text('支出'),
            subtitle: Text(expense ? '支出' : '收入'),
            value: expense,
            onChanged: (v) => setState(() => expense = v),
          ),
          ListTile(
            title: const Text('日期'),
            subtitle: Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selected != null && mounted) {
                setState(
                  () => date = DateTime(
                    selected.year,
                    selected.month,
                    selected.day,
                    date.hour,
                    date.minute,
                    date.second,
                  ),
                );
              }
            },
          ),
          TextFormField(
            controller: note,
            decoration: const InputDecoration(labelText: '备注（可选）'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? '保存中…' : '保存'),
          ),
        ],
      ),
    ),
  );
}
