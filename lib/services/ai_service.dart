import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  bool _initialized = false;
  String _currentModelName = 'gemini-3-flash';
  static const String _versionPrefsKey = 'selected_ai_version_v2';
  static const String _tierPrefsKey = 'selected_ai_tier_v2';

  String _currentVersion = '3.0';
  String _currentTier = 'Tư duy';

  // !!! QUAN TRỌNG: SAU KHI DEPLOY LÊN VERCEL XONG, HÃY DÁN ĐƯỜNG LINK VÀO ĐÂY !!!
  // Ví dụ: 'https://chitieuplus-proxy.vercel.app/api/gemini'
  final String _vercelProxyUrl = 'https://chitieu-plus.vercel.app/api/gemini';

  // Mapping of Version + Tier to Model ID (Chủ yếu để hiển thị UI)
  static const Map<String, Map<String, String>> _modelMap = {
    '2.5': {
      'Nhanh': 'gemini-2.5-flash-lite',
      'Tư duy': 'gemini-2.5-flash',
      'Pro': 'gemini-2.5-pro',
    },
    '3.0': {
      'Nhanh': 'gemini-3.1-flash-lite-preview',
      'Tư duy': 'gemini-3-flash-preview',
      'Pro': 'gemini-3.1-pro-preview',
    },
  };

  String get currentVersion => _currentVersion;
  String get currentTier => _currentTier;
  String get currentModelName => _currentModelName;

  // Lịch sử chat theo session (Client cần giữ để gửi lên Server vì Vercel là Stateless)
  final List<Map<String, dynamic>> _clientHistory = [];

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _currentVersion = prefs.getString(_versionPrefsKey) ?? '3.0';
    if (_currentVersion == '2.0') {
      _currentVersion = '3.0';
      await prefs.setString(_versionPrefsKey, '3.0');
    }

    _currentTier = prefs.getString(_tierPrefsKey) ?? 'Tư duy';
    _currentModelName =
        _modelMap[_currentVersion]?[_currentTier] ?? 'gemini-3.1-flash-preview';

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
    await prefs.setString(
      'lockout_$_currentModelName',
      lockoutTime.toIso8601String(),
    );
  }

  Future<void> updateModel(String modelName) async {
    if (_currentModelName == modelName) return;
    _currentModelName = modelName;
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
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<String> sendMessage(
    String text, {
    List<Map<String, dynamic>>? attachments,
    List<String>? contextStrings,
  }) async {
    await _ensureInitialized();

    final lockoutTime = await getLockoutTime();
    if (lockoutTime != null) {
      return "LIMIT_EXCEEDED";
    }

    if (_vercelProxyUrl.contains('YOUR_VERCEL_DOMAIN_HERE')) {
      return "LỖI: Chưa cấu hình Vercel Proxy URL. Vui lòng mở `ai_service.dart` và cập nhật biến `_vercelProxyUrl`.";
    }
    try {
      final payload = {
        'type': 'chat',
        'message': text,
        'history': _clientHistory,
        'version': _currentVersion,
        'tier': _currentTier,
        'contextStrings': contextStrings ?? [],
        'attachments': (attachments ?? [])
            .map(
              (att) => {
                'base64': att['bytes'] != null
                    ? base64Encode(att['bytes'] as Uint8List)
                    : null,
                'mimeType': att['mimeType'],
              },
            )
            .where((a) => a['base64'] != null)
            .toList(),
      };

      // Gửi yêu cầu qua thẻ POST
      final response = await http.post(
        Uri.parse(_vercelProxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Update client history
        _clientHistory.add({'role': 'user', 'text': text});
        _clientHistory.add({'role': 'ai', 'text': data['response']});

        return data['response'] ?? "Không có phản hồi từ AI.";
      } else if (response.statusCode == 429) {
        await _setLockout();
        return "LIMIT_EXCEEDED";
      } else {
        return "Lỗi từ Server (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      debugPrint('[AiService] Error HTTP: $e');
      return "Không thể kết nối với Vercel Server. Lỗi: $e";
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
      final payload = {
        'type': 'chat',
        'message':
            'Dựa vào tin nhắn sau, hãy tạo một tiêu đề siêu ngắn (tối đa 4 từ) cho cuộc hội thoại này. TRẢ VỀ DUY NHẤT TIÊU ĐỀ TRONG PHẦN MESSAGE CHO PHÉP, KHÔNG có dấu ngoặc kép hay giải thích.\n\n"$firstMessage"',
        'history': [],
        'version': _currentVersion,
        'tier': 'Nhanh',
      };

      final response = await http.post(
        Uri.parse(_vercelProxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String rawText = data['response'] ?? "Cuộc trò chuyện mới";

        // Vercel proxy always returns nested JSON for Gemini responses under 'message'
        try {
          final innerData = jsonDecode(rawText);
          if (innerData != null && innerData['message'] != null) {
            rawText = innerData['message'];
          }
        } catch (e) {
          // Ignored if not JSON
        }

        String title = rawText.replaceAll('"', '').replaceAll('*', '').trim();
        if (title.isEmpty) title = "Cuộc trò chuyện mới";

        _titleCache[cacheKey] = title;
        return title;
      }
      return "Cuộc trò chuyện mới";
    } catch (e) {
      debugPrint("Title generation error: $e");
      return "Cuộc trò chuyện mới";
    }
  }

  Future<String> generateCategory(String firstMessage) async {
    final cacheKey = firstMessage.hashCode.toString();
    if (_categoryCache.containsKey(cacheKey)) return _categoryCache[cacheKey]!;

    await _ensureInitialized();
    try {
      final payload = {
        'type': 'chat',
        'message':
            'Dựa vào tin nhắn sau, hãy phân loại nội dung vào MỘT trong các từ khóa: "Thu", "Chi", "Phân tích", "Chính sách", hoặc "Khác". CHỈ TRẢ VỀ DUY NHẤT TỪ KHÓA TRONG PHẦN MESSAGE, KHÔNG có ngoặc kép.\n\n"$firstMessage"',
        'history': [],
        'version': _currentVersion,
        'tier': 'Nhanh',
      };

      final response = await http.post(
        Uri.parse(_vercelProxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String rawText = data['response'] ?? "Khác";

        try {
          final innerData = jsonDecode(rawText);
          if (innerData != null && innerData['message'] != null) {
            rawText = innerData['message'];
          }
        } catch (e) {
          // Ignored if not JSON
        }

        String category = rawText
            .replaceAll('"', '')
            .replaceAll('*', '')
            .trim();
        if (category.isEmpty) category = "Khác";

        _categoryCache[cacheKey] = category;
        return category;
      }
      return "Khác";
    } catch (e) {
      debugPrint("Category generation error: $e");
      return "Khác";
    }
  }
}
