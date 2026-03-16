import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

class UrlProcessorService {
  static final UrlProcessorService _instance = UrlProcessorService._internal();
  factory UrlProcessorService() => _instance;
  UrlProcessorService._internal();

  /// Fetches content from a URL.
  /// If it's a YouTube URL, it tries to get basic info.
  /// If it's a general URL, it scrapes the text.
  Future<Map<String, String>> processUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        return await _processYouTubeUrl(url);
      } else {
        return await _processGeneralUrl(url);
      }
    } catch (e) {
      debugPrint('Error processing URL: $e');
      return {'title': 'URL không hợp lệ', 'content': 'Không thể truy cập nội dung từ liên kết này.'};
    }
  }

  Future<Map<String, String>> _processGeneralUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final title = document.head?.querySelector('title')?.text ?? 'Trang web';
        
        // Simple scraping: get text from p, h1, h2 tags
        final contentParts = document.body?.querySelectorAll('p, h1, h2, h3')
            .map((e) => e.text.trim())
            .where((text) => text.isNotEmpty)
            .take(50) // Limit to first 50 parts to avoid too much text
            .toList() ?? [];
            
        return {
          'title': title,
          'content': contentParts.join('\n\n'),
          'url': url,
        };
      }
      return {'title': 'Lỗi kết nối', 'content': 'Mã lỗi: ${response.statusCode}'};
    } catch (e) {
      return {'title': 'Lỗi', 'content': 'Không thể tải nội dung trang web: $e'};
    }
  }

  Future<Map<String, String>> _processYouTubeUrl(String url) async {
    // For YouTube, without a server-side proxy or official API key with transcript access,
    // we provide the URL and title. Gemini often "knows" popular videos or can reason from the title.
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final title = document.head?.querySelector('title')?.text ?? 'Video YouTube';
        return {
          'title': title.replaceAll(' - YouTube', ''),
          'content': 'Đây là một liên kết video YouTube. Vui lòng phân tích dựa trên tiêu đề và thông tin video này.',
          'url': url,
          'isYouTube': 'true',
        };
      }
      return {'title': 'YouTube Video', 'content': 'Liên kết video: $url'};
    } catch (e) {
      return {'title': 'YouTube Video', 'content': 'Liên kết video: $url'};
    }
  }
}
