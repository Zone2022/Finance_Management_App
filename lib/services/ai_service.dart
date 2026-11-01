import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._()
    : _client = http.Client(),
      _storage = const FlutterSecureStorage();
  AiService.forTesting(http.Client client, {FlutterSecureStorage? storage})
    : _client = client,
      // Keep the storage implementation private while allowing test injection.
      // ignore: prefer_initializing_formals
      _storage = storage;
  final http.Client _client;
  final FlutterSecureStorage? _storage;
  String selectedProvider = 'deepseek';
  final Map<String, String> _keys = {};
  Future<void>? _initializing;
  Future<void> initialize() =>
      _initializing ??= _load().catchError((Object error, StackTrace stack) {
        _initializing = null;
        Error.throwWithStackTrace(error, stack);
      });
  Future<void> _load() async {
    if (_storage == null) return;
    for (final provider in ['deepseek', 'claude']) {
      final value = await _storage.read(key: 'ai_key_$provider');
      if (value != null && value.isNotEmpty) _keys[provider] = value;
    }
    final selected = await _storage.read(key: 'ai_provider');
    if (selected == 'claude' || selected == 'deepseek') {
      selectedProvider = selected!;
    }
  }

  bool hasKey(String provider) => _keys[provider]?.isNotEmpty ?? false;
  Future<void> saveKey(String provider, String key) async {
    await initialize();
    if (key.trim().isEmpty) throw ArgumentError('Key 不能为空');
    await _storage?.write(key: 'ai_key_$provider', value: key.trim());
    _keys[provider] = key.trim();
  }

  Future<void> deleteKey(String provider) async {
    await initialize();
    await _storage?.delete(key: 'ai_key_$provider');
    _keys.remove(provider);
  }

  Future<void> selectProvider(String provider) async {
    await initialize();
    if (!['deepseek', 'claude'].contains(provider)) throw ArgumentError('未知服务');
    await _storage?.write(key: 'ai_provider', value: provider);
    selectedProvider = provider;
  }

  static const _baseUrl = 'https://api.deepseek.com/chat/completions';

  // Session-only: do not persist user credentials in plaintext.
  String? _apiKey;

  void setApiKey(String key) {
    _apiKey = key;
  }

  Future<String?> classify(String merchantName) async {
    await initialize();
    final key = _storage == null ? _apiKey : _keys[selectedProvider];
    if (key == null || key.isEmpty) return null;

    final prompt =
        '''
你是一个财务分类助手。请将以下商户名称归类到以下类别之一：
餐饮、交通、购物、居住、娱乐、医疗、教育、通讯、其他

只返回类别名称，不要解释。

商户: $merchantName
分类:''';

    try {
      final isClaude = selectedProvider == 'claude';
      final response = await _client
          .post(
            Uri.parse(
              isClaude ? 'https://api.anthropic.com/v1/messages' : _baseUrl,
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
              if (isClaude) 'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': isClaude ? 'claude-haiku-4-5' : 'deepseek-chat',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              if (!isClaude) 'temperature': 0.0,
              'max_tokens': isClaude ? 128 : 10,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        dynamic content;
        if (isClaude) {
          content = body['content']?[0]?['text'];
        } else {
          content = body['choices']?[0]?['message']?['content'];
        }
        final text = (content as String?)?.trim();
        if (const [
          '餐饮',
          '交通',
          '购物',
          '居住',
          '娱乐',
          '医疗',
          '教育',
          '通讯',
          '其他',
        ].contains(text)) {
          return text;
        }
      }
    } catch (_) {
      // Network error or timeout
    }

    return null;
  }
}
