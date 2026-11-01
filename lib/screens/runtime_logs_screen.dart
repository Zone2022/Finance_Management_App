import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_handler.dart';

class RuntimeLogsScreen extends StatefulWidget {
  const RuntimeLogsScreen({super.key});
  @override
  State<RuntimeLogsScreen> createState() => _RuntimeLogsScreenState();
}

class _RuntimeLogsScreenState extends State<RuntimeLogsScreen> {
  List<dynamic> logs = [];
  String? error;
  String status = '正在检查通知使用权…';
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!NotificationHandler.isSupported) {
      setState(() => error = '运行日志目前支持 Android');
      return;
    }
    try {
      final listener = await NotificationHandler().listenerStatus();
      final data = await NotificationHandler().getLogs();
      if (mounted) {
        setState(() {
          logs = data;
          error = null;
          status = listener['authorized'] != true
              ? '通知使用权未开启'
              : listener['connected'] == true
              ? '通知使用权已开启，监听服务已连接'
              : '通知使用权已开启，但监听服务未连接';
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '日志读取失败');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('运行日志'),
      actions: [
        IconButton(
          tooltip: '刷新',
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: '清空日志',
          onPressed: () async {
            await NotificationHandler().clearLogs();
            await refresh();
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$status\n仅保留最近 200 条状态，不记录通知正文、金额、账号或 Key。'),
        ),
        Expanded(
          child: error != null
              ? Center(child: Text(error!))
              : logs.isEmpty
              ? const Center(child: Text('暂无日志。请发起一笔测试支付后刷新。'))
              : ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = Map<String, dynamic>.from(logs[index] as Map);
                    return ListTile(
                      title: Text(row['message'] as String),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            row['time'] as int,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
