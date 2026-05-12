import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class NovelLink {
  final String title;
  final String url;
  final String platform;
  bool selected;

  NovelLink({
    required this.title,
    required this.url,
    required this.platform,
    this.selected = true,
  });
}

class LinkExtractor {
  static const Map<String, RegExp> _platformPatterns = {
    'RoyalRoad':   RegExp(r'https?://(?:www\.)?royalroad\.com/fiction/\d+', caseSensitive: false),
    'ScribbleHub': RegExp(r'https?://(?:www\.)?scribblehub\.com/series/\d+', caseSensitive: false),
    'NovelBin':    RegExp(r'https?://novelbin\.(com|me|net)/b/', caseSensitive: false),
    'NovelFire':   RegExp(r'https?://(?:www\.)?novelfire\.net/novel/', caseSensitive: false),
    'WebNovel':    RegExp(r'https?://(?:www\.)?webnovel\.com/book/', caseSensitive: false),
    'Wuxiaworld':  RegExp(r'https?://(?:www\.)?wuxiaworld\.com/novel/', caseSensitive: false),
    'NovelUpdates':RegExp(r'https?://(?:www\.)?novelupdates\.com/series/', caseSensitive: false),
  };

  /// Parse raw HTML string (from a saved .html file) and return all novel links found.
  static List<NovelLink> extractFromHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final anchors  = document.querySelectorAll('a[href]');
    final results  = <NovelLink>[];
    final seen     = <String>{};

    for (final anchor in anchors) {
      final href = anchor.attributes['href'] ?? '';
      if (href.isEmpty || seen.contains(href)) continue;

      for (final entry in _platformPatterns.entries) {
        if (entry.value.hasMatch(href)) {
          seen.add(href);
          results.add(NovelLink(
            title:    _resolveTitle(anchor, href),
            url:      href,
            platform: entry.key,
          ));
          break;
        }
      }
    }
    return results;
  }

  static String _resolveTitle(Element anchor, String url) {
    final text = anchor.text.trim();
    if (text.isNotEmpty && text.length < 120) return text;
    final slug = Uri.parse(url).pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => 'Unknown Novel',
    );
    return slug.replaceAll(RegExp(r'[-_]'), ' ').trim();
  }
}
