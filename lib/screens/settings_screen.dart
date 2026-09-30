import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/ai_service.dart';
import '../services/notification_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (NotificationHandler.isSupported) ...[
          const Text(
            '自动记账',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Text('请在系统设置中允许本应用读取通知。仅识别支持格式的支付成功通知；未出现通知的支付无法记录。'),
          TextButton.icon(
            icon: const Icon(Icons.notifications_active),
            label: const Text('打开通知使用权设置'),
            onPressed: () async {
              try {
                await NotificationHandler().openSettings();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('无法打开设置，请手动进入系统通知使用权设置')),
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'AI 分类设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          '接入 DeepSeek API 实现智能分类（可选）。\n启用后会将未匹配的商户名发送给 DeepSeek。Key 仅在本次运行有效，重启后需重新输入；留空可停用。',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          controller: _apiKeyController,
          decoration: InputDecoration(
            labelText: 'DeepSeek API Key',
            hintText: 'sk-...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                AiService().setApiKey(_apiKeyController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI 设置已应用（仅本次运行）')),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '支出分类',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...Category.defaults.map(_buildCategoryTile),
        const SizedBox(height: 24),
        const Text(
          '关于',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('个人财务管理', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Divider(height: 24),
                Text(
                  '通过拦截微信和支付宝支付通知，自动记录并分类消费。\n支持月度/年度财务报表分析。',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCategoryTile(Category cat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat.color.withValues(alpha: 0.15),
          child: Icon(cat.icon, color: cat.color, size: 20),
        ),
        title: Text(cat.name),
      ),
    );
  }
}
