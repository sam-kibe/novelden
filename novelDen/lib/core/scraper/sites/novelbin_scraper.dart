import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/chapter.dart';
import '../base_scraper.dart';
import '../../../shared/utils/delay_util.dart';

/// Scraper for novelbin.com (also covers novelbin.me / novelbin.net mirrors)
/// Chapter list is loaded via an AJAX endpoint that returns paginated HTML.
class NovelbinScraper extends BaseScraper {
  NovelbinScraper(super.template);

  @override
  Future<List<String>> fetchChapterList(String novelUrl) async {
    // Normalize URL and extract slug
    // e.g. https://novelbin.com/b/some-novel-slug
    final uri = Uri.parse(novelUrl);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // slug is usually the last meaningful segment
    final slug = segments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => throw ScrapeException('Cannot parse novel slug from $novelUrl'),
    );

    final allChapters = <String>[];
    int page = 1;
    bool hasMore = true;
    final base = '${uri.scheme}://${uri.host}';

    while (hasMore) {
      await DelayUtil.humanDelay();

      // NovelBin chapter-list AJAX endpoint
      final ajaxUrl = '$base/ajax/chapter-archive?novelId=$slug&page=$page';
      final Response<String> response;

      try {
        response = await Dio(BaseOptions(
          headers: {
            'User-Agent': _ua,
            'Referer': novelUrl,
            'X-Requested-With': 'XMLHttpRequest',
          },
        )).get<String>(ajaxUrl);
      } on DioException catch (e) {
        // Fall back to scraping the HTML directly on first page
        if (page == 1) return _fallbackHtmlParse(novelUrl, base);
        break;
      }

      final doc = html_parser.parse(response.data ?? '');
      final links = doc.querySelectorAll('li.chapter-item a, ul.list-chapter a');

      if (links.isEmpty) {
        hasMore = false;
      } else {
        for (final a in links) {
          final href = a.attributes['href'] ?? '';
          if (href.isEmpty) continue;
          allChapters.add(
            href.startsWith('http') ? href : '$base$href',
          );
        }
        page++;
      }
    }

    return allChapters;
  }

  Future<List<String>> _fallbackHtmlParse(String novelUrl, String base) async {
    final response = await Dio(BaseOptions(
      headers: {'User-Agent': _ua, 'Referer': base},
    )).get<String>(novelUrl);

    final doc = html_parser.parse(response.data ?? '');
    return doc
        .querySelectorAll('#chapter-list a, .chapter-list a, li.chapter-item a')
        .map((a) => a.attributes['href'] ?? '')
        .where((h) => h.isNotEmpty)
        .map((h) => h.startsWith('http') ? h : '$base$h')
        .toList();
  }

  @override
  Future<ScrapedChapter> fetchChapter(String url) async {
    await DelayUtil.humanDelay();
    final base = Uri.parse(url).origin;

    final response = await Dio(BaseOptions(
      headers: {'User-Agent': _ua, 'Referer': base},
    )).get<String>(url);

    final doc = html_parser.parse(response.data ?? '');

    // Strip junk before reading
    for (final sel in [
      '.ads', '.ad-container', '#ads', '.locked-chapter',
      '.chapter-warning', 'script', 'style',
    ]) {
      doc.querySelectorAll(sel).forEach((e) => e.remove());
    }

    final title = doc.querySelector('h2, .chapter-title, .chr-title')?.text.trim() ?? 'Chapter';
    final body  = doc.querySelector('#chr-content, .chr-content, #chapter-content, .chapter-content');

    if (body == null) {
      throw ScrapeException('Body not found at $url — selector may need updating');
    }

    return ScrapedChapter(
      title: title,
      content: _clean(body.innerHtml),
      sourceUrl: url,
    );
  }

  String _clean(String html) => html
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
      .replaceAll(RegExp(r' style="[^"]*"'), '')
      .replaceAll(RegExp(r' class="[^"]*"'), '')
      .trim();

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
}
