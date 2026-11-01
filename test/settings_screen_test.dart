import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_finance/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('provider keys are entered in a dialog and selection is saved', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SettingsScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byTooltip('配置 DeepSeek'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret-test-value');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.textContaining('已保存 Key'), findsOneWidget);
    expect(find.text('secret-test-value'), findsNothing);
    await tester.tap(find.text('使用'));
    await tester.pumpAndSettle();
    expect(find.textContaining('当前使用'), findsOneWidget);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'ai_key_deepseek'), 'secret-test-value');
    expect(await storage.read(key: 'ai_provider'), 'claude');
  });
}
