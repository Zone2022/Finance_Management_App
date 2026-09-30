import '../database/database_helper.dart';
import 'ai_service.dart';

class ClassificationService {
  final DatabaseHelper _db = DatabaseHelper();
  final AiService _ai = AiService();

  Future<String> classify(String merchantName) async {
    merchantName = merchantName.trim();
    if (merchantName.isEmpty || merchantName == '未知商户') return '其他';
    final localMatch = await _db.matchCategory(merchantName);
    if (localMatch != null) return localMatch;

    try {
      final aiResult = await _ai.classify(merchantName);
      if (aiResult != null && aiResult != '其他') {
        await _db.addMerchantRule(merchantName, aiResult);
        return aiResult;
      }
    } catch (_) {
      // AI call failed, silently fall back to default
    }

    return '其他';
  }
}
