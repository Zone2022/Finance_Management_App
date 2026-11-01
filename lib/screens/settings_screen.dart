import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/category.dart';
import '../services/ai_service.dart';
import '../services/notification_handler.dart';
import 'runtime_logs_screen.dart';
import 'merchant_rules_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ai = AiService();
  String? storageError;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ai.initialize();
    } catch (_) {
      storageError = '安全存储不可用，请检查设备后重试';
    }
    if (mounted) setState(() {});
  }

  Future<void> _configure(String provider) async {
    final controller = TextEditingController();
    final name = provider == 'deepseek' ? 'DeepSeek' : 'Claude';
    final route = DialogRoute<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('配置 $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ai.hasKey(provider)
                  ? '已保存 Key。输入新 Key 可以替换。'
                  : '输入 API Key，保存后在此设备上使用。',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (ai.hasKey(provider))
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'delete'),
              child: const Text('删除 Key'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'cancel'),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final action = await Navigator.of(context).push(route);
    final key = controller.text.trim();
    await route.completed;
    controller.dispose();
    if (!mounted || action == null || action == 'cancel') return;
    try {
      if (action == 'delete') {
        await ai.deleteKey(provider);
      } else {
        await ai.saveKey(provider, key);
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'delete' ? 'Key 已删除' : 'Key 已保存；使用时会连接对应服务'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请检查 Key 和设备安全存储')));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        '自动记账',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text('需要允许通知使用权。银行与支付平台可能同时提醒同一笔交易，请核对重复记录。'),
      if (NotificationHandler.isSupported)
        TextButton.icon(
          onPressed: () async {
            try {
              await NotificationHandler().openSettings();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('无法打开通知设置')));
              }
            }
          },
          icon: const Icon(Icons.notifications_outlined),
          label: const Text('打开通知使用权设置'),
        ),
      ValueListenableBuilder<String?>(
        valueListenable: NotificationHandler().importError,
        builder: (context, error, _) => error == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Text(error),
                  TextButton(
                    onPressed: () => NotificationHandler().retryImport(),
                    child: const Text('重试导入'),
                  ),
                ],
              ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.receipt_long_outlined),
        title: const Text('运行日志'),
        subtitle: const Text('查看通知接收与导入状态'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RuntimeLogsScreen()),
        ),
      ),
      const Divider(height: 32),
      const Text(
        '智能分类',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text('本地规则优先；仅未匹配的商户名会发送给选中的服务。'),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.rule_outlined),
        title: const Text('商户分类规则'),
        subtitle: const Text('查看、搜索和修改本地规则'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MerchantRulesScreen()),
        ),
      ),
      if (storageError != null)
        Text(storageError!, style: const TextStyle(color: Colors.red)),
      for (final entry in const [
        ('deepseek', 'DeepSeek', Icons.auto_awesome_outlined),
        ('claude', 'Claude', Icons.blur_on_outlined),
      ])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SvgPicture.asset(
            'assets/brands/${entry.$1}.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.black87,
              BlendMode.srcIn,
            ),
          ),
          title: Text(entry.$2),
          subtitle: Text(
            '${ai.hasKey(entry.$1) ? '已保存 Key' : '未配置'}${ai.selectedProvider == entry.$1 ? ' · 当前使用' : ''}',
          ),
          trailing: Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ai.selectedProvider != entry.$1)
                TextButton(
                  onPressed: () async {
                    try {
                      await ai.selectProvider(entry.$1);
                      if (mounted) setState(() {});
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('切换失败')));
                      }
                    }
                  },
                  child: const Text('使用'),
                ),
              IconButton(
                tooltip: '配置 ${entry.$2}',
                onPressed: () => _configure(entry.$1),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
      const Divider(height: 32),
      const Text(
        '支出分类',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      ...Category.defaults.map(
        (cat) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(cat.icon, color: cat.color),
          title: Text(cat.name),
        ),
      ),
      const Divider(height: 32),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Miko Finance'),
        subtitle: Text('个人财务管理'),
      ),
    ],
  );
}
