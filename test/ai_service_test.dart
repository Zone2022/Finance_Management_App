import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_finance/services/ai_service.dart';

void main() {
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
}
