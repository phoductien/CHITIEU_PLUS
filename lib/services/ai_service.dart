import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  late GenerativeModel _model;
  late GenerativeModel _utilityModel;
  late ChatSession _chatSession;
  bool _initialized = false;
  String _currentModelName = 'gemini-3-flash';
  static const String _versionPrefsKey = 'selected_ai_version_v2';
  static const String _tierPrefsKey = 'selected_ai_tier_v2';

  String _currentVersion = '3.0';
  String _currentTier = 'Tư duy';

  // Mapping of Version + Tier to Model ID
  static const Map<String, Map<String, String>> _modelMap = {
    '2.0': {
      'Nhanh': 'gemini-2.0-flash-lite',
      'Tư duy': 'gemini-2.0-flash',
      'Pro': 'gemini-2.0-flash-001', // Using stable flash as Pro for 2.0
    },
    '2.5': {
      'Nhanh': 'gemini-2.5-flash-lite',
      'Tư duy': 'gemini-2.5-flash',
      'Pro': 'gemini-2.5-pro',
    },
    '3.0': {
      'Nhanh': 'gemini-3.1-flash-lite-preview',
      'Tư duy': 'gemini-3-flash-preview',
      'Pro': 'gemini-3.1-pro-preview',
    }
  };

  String get currentVersion => _currentVersion;
  String get currentTier => _currentTier;
  String get currentModelName => _currentModelName;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _currentVersion = prefs.getString(_versionPrefsKey) ?? '3.0';
    _currentTier = prefs.getString(_tierPrefsKey) ?? 'Tư duy';
    _currentModelName = _modelMap[_currentVersion]?[_currentTier] ?? 'gemini-3-flash';

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[AiService] CRITICAL ERROR: GEMINI_API_KEY is not set in .env file.');
      _initialized = false;
      return;
    }

    _model = GenerativeModel(
        model: _currentModelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          responseMimeType: 'application/json',
        ),
        systemInstruction: Content.system('''
Bạn là một trợ lý quản lý tài chính thông minh của ứng dụng ChiTieuPlus.

KIẾN THỨC & TƯ DUY:
- Ngoài các logic nghiệp vụ dưới đây, bạn được khuyến khích sử dụng kho kiến thức rộng lớn của mình (World Knowledge) để hỗ trợ người dùng đa dạng các chủ đề.
- Đặc tính phản hồi dựa trên phân tầng model:
    1. Gemini Flash (Nhanh): Tập trung vào tốc độ phản hồi cực nhanh và hiệu suất xử lý khối lượng lớn dữ liệu, trả lời gần như tức thì.
    2. Gemini Thinking (Tư duy): Sử dụng suy luận logic sâu sắc, phân tích vấn đề theo hướng trình bày từng bước (Chain-of-Thought).
    3. Gemini Pro (Nâng cao): Sự cân bằng hoàn hảo giữa sự thông minh vượt trội và tốc độ xử lý nhanh.

LOGIC TÀI CHÍNH QUAN TRỌNG:
- Mọi giao dịch người dùng nhập (ví dụ: "Ăn sáng 20k") đều được coi là Chi tiêu (expense).
- Thu nhập (income) được hiểu là số tiền còn lại trong ví sau khi đã trừ các khoản chi tiêu.
- Nếu số dư trong ví nhỏ hơn 0 (âm), đó là Khoản nợ.
- Nếu số dư chuyển từ trạng thái âm sang dương, phần chênh lệch đó được tính là Thu nhập.

QUY TẮC CỐ ĐỊNH:
1. Luôn phản hồi JSON.
2. Cấu trúc JSON:
{
  "message": "Lời nhắn tự nhiên",
  "transaction": {
    "title": "Tiêu đề",
    "amount": double,
    "category": "Ăn uống|Mua sắm|Di chuyển|Nhà cửa|Giải trí|Lương|Khác",
    "type": "expense",
    "note": "Ghi chú",
    "wallet": "main"
  }
} (transaction để null nếu chỉ câu hỏi đáp/phân tích).
3. Luôn ưu tiên độ chính xác số tiền (k=1000, tr=1tr).
4. Ngôn ngữ: Tiếng Việt.
'''),
      );

    _chatSession = _model.startChat();
    _initialized = true;
  }

  Future<DateTime?> getLockoutTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutStr = prefs.getString('lockout_$_currentModelName');
    if (lockoutStr == null) return null;
    
    final lockoutTime = DateTime.parse(lockoutStr);
    if (DateTime.now().isAfter(lockoutTime)) {
      await prefs.remove('lockout_$_currentModelName');
      return null;
    }
    return lockoutTime;
  }

  Future<void> _setLockout() async {
    final lockoutTime = DateTime.now().add(const Duration(hours: 24));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lockout_$_currentModelName', lockoutTime.toIso8601String());
  }

  Future<void> updateModel(String modelName) async {
    if (_currentModelName == modelName) return;
    _currentModelName = modelName;
    await _reinitModel();
  }

  Future<void> updateConfig({String? version, String? tier}) async {
    final prefs = await SharedPreferences.getInstance();
    if (version != null) {
      _currentVersion = version;
      await prefs.setString(_versionPrefsKey, version);
    }
    if (tier != null) {
      _currentTier = tier;
      await prefs.setString(_tierPrefsKey, tier);
    }

    final newModelId = _modelMap[_currentVersion]?[_currentTier];
    if (newModelId != null && newModelId != _currentModelName) {
      _currentModelName = newModelId;
      await _reinitModel();
    }
  }

  Future<void> _reinitModel() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[AiService] CRITICAL ERROR: GEMINI_API_KEY is not set in .env file.');
      _initialized = false;
      return;
    }

    _model = GenerativeModel(
        model: _currentModelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          responseMimeType: 'application/json',
        ),
        systemInstruction: Content.system('''
Bạn là một trợ lý quản lý tài chính thông minh của ứng dụng ChiTieuPlus.

KIẾN THỨC & TƯ DUY:
- Ngoài các logic nghiệp vụ dưới đây, bạn được khuyến khích sử dụng kho kiến thức rộng lớn của mình (World Knowledge) để hỗ trợ người dùng đa dạng các chủ đề.
- Đặc tính phản hồi dựa trên phân tầng model:
    1. Gemini Flash (Nhanh): Tập trung vào tốc độ phản hồi cực nhanh và hiệu suất xử lý khối lượng lớn dữ liệu, trả lời gần như tức thì.
    2. Gemini Thinking (Tư duy): Sử dụng suy luận logic sâu sắc, phân tích vấn đề theo hướng trình bày từng bước (Chain-of-Thought).
    3. Gemini Pro (Nâng cao): Sự cân bằng hoàn hảo giữa sự thông minh vượt trội và tốc độ xử lý nhanh.

LOGIC TÀI CHÍNH QUAN TRỌNG:
- Mọi giao dịch người dùng nhập (ví dụ: "Ăn sáng 20k") đều được coi là Chi tiêu (expense).
- Thu nhập (income) được hiểu là số tiền còn lại trong ví sau khi đã trừ các khoản chi tiêu.
- Nếu số dư trong ví nhỏ hơn 0 (âm), đó là Khoản nợ.
- Nếu số dư chuyển từ trạng thái âm sang dương, phần chênh lệch đó được tính là Thu nhập.

QUY TẮC CỐ ĐỊNH:
1. Luôn phản hồi JSON.
2. Cấu trúc JSON:
{
  "message": "Lời nhắn tự nhiên",
  "transaction": {
    "title": "Tiêu đề",
    "amount": double,
    "category": "Ăn uống|Mua sắm|Di chuyển|Nhà cửa|Giải trí|Lương|Khác",
    "type": "expense",
    "note": "Ghi chú",
    "wallet": "main"
  }
} (transaction để null nếu chỉ câu hỏi đáp/phân tích).
3. Luôn ưu tiên độ chính xác số tiền (k=1000, tr=1tr).
4. Ngôn ngữ: Tiếng Việt.
'''),
      );
    _chatSession = _model.startChat();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<String> sendMessage(String text, {List<Map<String, dynamic>>? attachments, List<String>? contextStrings}) async {
    await _ensureInitialized();
    if (!_initialized) return "Chưa cấu hình API Key cho AI. Vui lòng kiểm tra file .env";

    final lockoutTime = await getLockoutTime();
    if (lockoutTime != null) {
      return "LIMIT_EXCEEDED";
    }

    try {
      final List<Part> parts = [];
      
      if (contextStrings != null && contextStrings.isNotEmpty) {
        // Tối ưu ngữ cảnh: Chỉ lấy tối đa 3 context cuối cùng nếu quá nhiều
        final filteredContext = contextStrings.length > 5 ? contextStrings.sublist(contextStrings.length - 5) : contextStrings;
        for (var ctx in filteredContext) {
          parts.add(TextPart("--- Ngữ cảnh ---\n$ctx\n"));
        }
      }

      parts.add(TextPart(text));

      if (attachments != null && attachments.isNotEmpty) {
        for (var att in attachments) {
          if (att['bytes'] != null) {
            parts.add(DataPart(att['mimeType'] as String, att['bytes'] as Uint8List));
          }
        }
      }
      
      final response = await _chatSession.sendMessage(Content.multi(parts));
      return response.text ?? "Xin lỗi, tôi không thể xử lý yêu cầu này lúc này.";
    } on GenerativeAIException catch (e) {
      if (e.message.contains('Quota exceeded')) {
        await _setLockout();
        return "LIMIT_EXCEEDED"; 
      }
      return "Đã xảy ra lỗi AI: ${e.message}";
    } catch (e) {
      debugPrint('[AiService] Error: $e');
      return "Đã xảy ra lỗi khi kết nối với AI.";
    }
  }

  // Caching map đơn giản để tránh gọi lại API cho cùng một input trong cùng một phiên làm việc
  final Map<String, String> _titleCache = {};
  final Map<String, String> _categoryCache = {};

  Future<String> generateTitle(String firstMessage) async {
    final cacheKey = firstMessage.hashCode.toString();
    if (_titleCache.containsKey(cacheKey)) return _titleCache[cacheKey]!;

    await _ensureInitialized();
    try {
      final prompt = "Tạo tiêu đề ngắn (<4 từ) cho: '$firstMessage'. Chỉ trả về tiêu đề.";
      final response = await _utilityModel.generateContent([Content.text(prompt)]);
      final title = response.text?.replaceAll('"', '').trim() ?? "Cuộc trò chuyện mới";
      _titleCache[cacheKey] = title;
      return title;
    } catch (e) {
      return "Cuộc trò chuyện mới";
    }
  }

  Future<String> generateCategory(String firstMessage) async {
    final cacheKey = firstMessage.hashCode.toString();
    if (_categoryCache.containsKey(cacheKey)) return _categoryCache[cacheKey]!;

    await _ensureInitialized();
    try {
      final prompt = "Phân loại vào: 'Tài chính', 'Mua sắm', 'Hỏi đáp', 'Phân tích', 'Công việc', 'Giải trí', 'Học tập', 'Khác'. Chỉ trả về 1 tên. Input: '$firstMessage'";
      final response = await _utilityModel.generateContent([Content.text(prompt)]);
      final category = response.text?.replaceAll('"', '').trim() ?? "Khác";
      _categoryCache[cacheKey] = category;
      return category;
    } catch (e) {
      return "Khác";
    }
  }
}
