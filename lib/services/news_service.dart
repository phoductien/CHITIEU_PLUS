import 'package:http/http.dart' as http;
import 'package:webfeed_revised/webfeed_revised.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/foundation.dart';

class NewsArticle {
  final String title;
  final String link;
  final String pubDate;
  final String description;
  final String? imageUrl;
  final String source;

  NewsArticle({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
    this.imageUrl,
    required this.source,
  });
}

class NewsService {
  static const List<Map<String, String>> _sources = [
    {
      'url': 'https://vneconomy.vn/tai-chinh.htm',
      'name': 'VnEconomy',
    },
    {
      'url': 'https://vnbusiness.vn/tai-chinh',
      'name': 'VnBusiness',
    },
    {
      'url': 'https://vnbusiness.vn/rss/tieu-dung.rss',
      'name': 'VnBusiness',
    },
    {
      'url': 'https://cafef.vn/tai-chinh-ngan-hang.rss',
      'name': 'CafeF',
    },
    {
      'url': 'https://vnexpress.net/rss/kinh-doanh.rss',
      'name': 'VnExpress',
    },
  ];

  static const List<String> _keywords = [
    'tiết kiệm',
    'tài chính',
    'chi tiêu',
    'ngân sách',
    'đầu tư',
    'lãi suất',
    'ngân hàng',
    'vàng',
    'ví',
    'tiền',
  ];

  Future<List<NewsArticle>> fetchSavingsNews() async {
    List<NewsArticle> allArticles = [];

    for (var source in _sources) {
      try {
        String url = source['url']!;
        if (kIsWeb) {
          // Use a CORS proxy for web to avoid CORS blocks
          url = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
        }
        
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          var rssFeed = RssFeed.parse(response.body);
          
          for (var item in rssFeed.items ?? []) {
            final title = item.title ?? '';
            final description = _stripHtml(item.description ?? '');
            
            // Filter by keywords
            bool matches = _keywords.any((kw) => 
              title.toLowerCase().contains(kw) || 
              description.toLowerCase().contains(kw)
            );

            if (matches || allArticles.length < 5) { // Relax filtering if we don't have enough
              allArticles.add(NewsArticle(
                title: title,
                link: item.link ?? '',
                pubDate: item.pubDate?.toString() ?? '',
                description: description,
                imageUrl: _extractImageUrl(item.description ?? '') ?? _extractImageUrlFromContent(item.content?.value ?? ''),
                source: source['name']!,
              ));
            }
          }
        }
      } catch (e) {
        print('Error fetching news from ${source['name']}: $e');
      }
    }

    // Add fallback tips if still empty
    if (allArticles.isEmpty) {
      allArticles.addAll(_getFallbackTips());
    }

    return allArticles;
  }

  List<NewsArticle> _getFallbackTips() {
    return [
      NewsArticle(
        title: '6 quy tắc vàng giúp bạn tiết kiệm tiền hiệu quả',
        link: 'https://vneconomy.vn/6-quy-tac-vang-giup-ban-tiet-kiem-tien-hieu-qua.htm',
        pubDate: DateTime.now().toString(),
        description: 'Quản lý tài chính cá nhân là một kỹ năng quan trọng giúp bạn đạt được các mục tiêu trong cuộc sống...',
        source: 'Tư vấn',
      ),
      NewsArticle(
        title: 'Cách lập kế hoạch chi tiêu gia đình trong 1 tháng',
        link: 'https://vnbusiness.vn/tu-van/cach-lap-ke-hoach-chi-tieu-gia-dinh-trong-1-thang-1082522.html',
        pubDate: DateTime.now().toString(),
        description: 'Việc lập kế hoạch chi tiêu giúp bạn kiểm soát dòng tiền và tránh những khoản chi không cần thiết...',
        source: 'Tư vấn',
      ),
      NewsArticle(
        title: 'Mẹo tiết kiệm điện nước tối đa cho hộ gia đình',
        link: 'https://vnexpress.net/meo-tiet-kiem-dien-nuoc-4735000.html',
        pubDate: DateTime.now().toString(),
        description: 'Những thói quen nhỏ hàng ngày có thể giúp bạn giảm đáng kể hóa đơn tiền điện nước mỗi tháng...',
        source: 'Mẹo vặt',
      ),
    ];
  }

  String _stripHtml(String htmlString) {
    var document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }

  String? _extractImageUrl(String htmlString) {
    try {
      var document = html_parser.parse(htmlString);
      var img = document.querySelector('img');
      return img?.attributes['src'];
    } catch (e) {
      return null;
    }
  }

  String? _extractImageUrlFromContent(String htmlString) {
    if (htmlString.isEmpty) return null;
    try {
      var document = html_parser.parse(htmlString);
      var img = document.querySelector('img');
      return img?.attributes['src'];
    } catch (e) {
      return null;
    }
  }
}
