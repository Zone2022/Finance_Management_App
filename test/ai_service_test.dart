import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_finance/services/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('settings and classifier share the same service instance', () {
    expect(identical(AiService(), AiService()), isTrue);
  });
  test('no key skips external requests', () async {
    final client = MockClient((_) async => throw StateError('Must not call'));
    addTearDown(client.close);
    expect(await AiService.forTesting(client).classify('测试商户'), isNull);
  });
  test('UTF-8 category is decoded and invalid AI output rejected', () async {
    var content = '餐饮';
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-key');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'choices': [
              {
                'message': {'content': content},
              },
            ],
          }),
        ),
        200,
      );
    });
    addTearDown(client.close);
    final ai = AiService.forTesting(client)..setApiKey('test-key');
    expect(await ai.classify('测试商户'), '餐饮');
    content = '餐饮，因为这是餐厅';
    expect(await ai.classify('测试商户'), isNull);
  });
  test('HTTP failure falls back', () async {
    final client = MockClient((_) async => http.Response('', 429));
    addTearDown(client.close);
    final ai = AiService.forTesting(client)..setApiKey('test-key');
    expect(await ai.classify('测试商户'), isNull);
  });

  test('Claude uses messages endpoint and parses category response', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.anthropic.com');
      expect(request.url.path, '/v1/messages');
      expect(request.headers['anthropic-version'], '2023-06-01');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'content': [
              {'type': 'text', 'text': '交通'},
            ],
          }),
        ),
        200,
      );
    });
    addTearDown(client.close);
    final ai = AiService.forTesting(client)..setApiKey('test-key');
    await ai.selectProvider('claude');
    expect(await ai.classify('测试商户'), '交通');
  });

  test('saved provider and keys restore in a new service instance', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final client = MockClient((_) async => http.Response('', 500));
    addTearDown(client.close);
    final first = AiService.forTesting(client, storage: storage);
    await first.saveKey('deepseek', 'deepseek-test');
    await first.saveKey('claude', 'claude-test');
    await first.selectProvider('claude');
    final restored = AiService.forTesting(client, storage: storage);
    await restored.initialize();
    expect(restored.selectedProvider, 'claude');
    expect(restored.hasKey('deepseek'), isTrue);
    expect(restored.hasKey('claude'), isTrue);
    await restored.deleteKey('claude');
    expect(restored.hasKey('claude'), isFalse);
  });
}
