import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/merchant_rule.dart';

class MerchantRulesScreen extends StatefulWidget {
  const MerchantRulesScreen({super.key});
  @override
  State<MerchantRulesScreen> createState() => _MerchantRulesScreenState();
}

class _MerchantRulesScreenState extends State<MerchantRulesScreen> {
  List<MerchantRule> rules = [];
  String search = '';
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await context.read<DatabaseHelper>().getMerchantRules();
      if (!mounted) return;
      setState(() {
        rules = result;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = '规则加载失败，请重试';
        });
      }
    }
  }

  Future<void> _edit([MerchantRule? rule]) async {
    final controller = TextEditingController(text: rule?.keyword ?? '');
    String category = Category.defaults.any((c) => c.name == rule?.category)
        ? rule!.category
        : '其他';
    final route = DialogRoute<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(rule == null ? '新增规则' : '编辑规则'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '商户关键词',
                  helperText: '商户名称包含该关键词时匹配',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: '分类'),
                items: Category.defaults
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c.name, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => category = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入商户关键词')));
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    final shouldSave = await Navigator.of(context).push(route);
    final keyword = controller.text.trim();
    await route.completed;
    controller.dispose();
    if (!mounted || shouldSave != true) return;
    try {
      final db = context.read<DatabaseHelper>();
      if (rule == null) {
        await db.createMerchantRule(keyword, category);
      } else if (await db.updateMerchantRule(rule.id, keyword, category) != 1) {
        throw StateError('规则不存在');
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('规则保存失败，请重试')));
      }
    }
  }

  Future<void> _delete(MerchantRule rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除规则？'),
        content: Text('删除“${rule.keyword}”后，新的交易将不再使用此规则。已有交易不会改变。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    try {
      await context.read<DatabaseHelper>().deleteMerchantRule(rule.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = rules
        .where(
          (rule) =>
              rule.keyword.toLowerCase().contains(search.toLowerCase()) ||
              rule.category.contains(search),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('商户分类规则'),
        actions: [
          IconButton(
            tooltip: '新增规则',
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('商户名称包含关键词时应用分类；关键词越长优先级越高，相同长度时新规则优先。规则修改只影响之后的分类。'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => search = value.trim()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: '搜索关键词或分类',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error!),
                        TextButton(onPressed: _load, child: const Text('重试')),
                      ],
                    ),
                  )
                : filtered.isEmpty
                ? const Center(child: Text('没有匹配的规则'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final rule = filtered[index];
                      return ListTile(
                        title: Text(rule.keyword),
                        subtitle: Text(rule.category),
                        onTap: () => _edit(rule),
                        trailing: IconButton(
                          tooltip: '删除 ${rule.keyword}',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(rule),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
