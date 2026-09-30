import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._() : _client = http.Client();
  AiService.forTesting(http.Client client) : _client = client;
  final http.Client _client;
  static const _baseUrl = 'https://api.deepseek.com/chat/completions';

  // Session-only: do not persist user credentials in plaintext.
  String? _apiKey;

  void setApiKey(String key) {
    _apiKey = key;
  }

  Future<String?> classify(String merchantName) async {
    if (_apiKey == null || _apiKey!.isEmpty) return null;

    final prompt =
        '''
你是一个财务分类助手。请将以下商户名称归类到以下类别之一：
餐饮、交通、购物、居住、娱乐、医疗、教育、通讯、其他

只返回类别名称，不要解释。

商户: $merchantName
分类:''';

    try {
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'deepseek-chat',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.0,
              'max_tokens': 10,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final text = (body['choices']?[0]?['message']?['content'] as String?)
            ?.trim();
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
