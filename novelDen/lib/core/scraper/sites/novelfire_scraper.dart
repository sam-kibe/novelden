import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/chapter.dart';
import '../base_scraper.dart';
import '../../../shared/utils/delay_util.dart';

/// Scraper for novelfire.net
/// NovelFire stores its chapter list on the novel's main page and uses
/// sequential pagination (?page=N) for long novels.
class NovelFireScraper extends BaseScraper {
  NovelFireScraper(super.template);

  @override
  Future<List<String>> fetchChapterList(String novelUrl) async {
    final allChapters = <String>[];
    final base = Uri.parse(novelUrl).origin;

    // Page 1 — also extract total page count
    final firstDoc = await _fetchDoc(novelUrl);
    _collectLinks(firstDoc, base, allChapters);

    // Find last page number from pagination
    final lastPage = _detectLastPage(firstDoc);

    // Fetch remaining pages
    for (int page = 2; page <= lastPage; page++) {
      await DelayUtil.humanDelay();
      final pageUrl = _buildPageUrl(novelUrl, page);
      final doc = await _fetchDoc(pageUrl);
      _collectLinks(doc, base, allChapters);
    }

    return allChapters;
  }

  @override
  Future<ScrapedChapter> fetchChapter(String url) async {
    await DelayUtil.humanDelay();
    final doc = await _fetchDoc(url);

    // Remove noise
    for (final sel in [
      '.ads', '.ad', '#ads', '.chapter-warning',
      '.novel-header', 'script', 'style', 'nav',
      '.chapter-nav', '.comment-section', 'footer',
    ]) {
      doc.querySelectorAll(sel).forEach((e) => e.remove());
    }

    final title = doc
            .querySelector('h2.chapter-title, h1.chapter-title, .chapter-title')
            ?.text
            .trim() ??
        'Chapter';

    // NovelFire wraps content in #chapter-container or .chapter-content
    final body = doc.querySelector(
      '#chapter-container, .chapter-content, .content-text, article.chapter',
    );

    if (body == null) {
      throw ScrapeException('Could not find chapter body at $url');
    }

    // NovelFire sometimes wraps paragraphs in <p> with ads injected as spans
    body.querySelectorAll('span.adsf, .ads-inline, a[href*="novelfire"]')
        .forEach((e) => e.remove());

    return ScrapedChapter(
      title: title,
      content: _clean(body.innerHtml),
      sourceUrl: url,
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<dynamic> _fetchDoc(String url) async {
    final response = await Dio(BaseOptions(
      headers: {
        'User-Agent': _ua,
        'Referer': 'https://novelfire.net/',
        'Accept': 'text/html,application/xhtml+xml',
      },
      connectTimeout: const Duration(seconds: 20),
    )).get<String>(url);
    return html_parser.parse(response.data ?? '');
  }

  void _collectLinks(dynamic doc, String base, List<String> out) {
    final links = (doc.querySelectorAll(
          'ul.chapter-list a, .chapter-list li a, '
          '#chapter-list a, .list-chapter a',
        ) as List)
        .map((a) => (a.attributes['href'] ?? '') as String)
        .where((h) => h.isNotEmpty)
        .map((h) => h.startsWith('http') ? h : '$base$h');
    out.addAll(links);
  }

  int _detectLastPage(dynamic doc) {
    // Pagination typically: <a href="...?page=12">Last</a> or aria-label="Last"
    final pageLinks = doc.querySelectorAll(
      'ul.pagination a, .pagination a[href*="page="]',
    ) as List;
    int max = 1;
    for (final a in pageLinks) {
      final href = (a.attributes['href'] ?? '') as String;
      final match = RegExp(r'[?&]page=(\d+)').firstMatch(href);
      if (match != null) {
        final n = int.tryParse(match.group(1) ?? '') ?? 1;
        if (n > max) max = n;
      }
    }
    return max;
  }

  String _buildPageUrl(String novelUrl, int page) {
    final uri = Uri.parse(novelUrl);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'page': page.toString(),
    }).toString();
  }

  String _clean(String html) => html
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
      .replaceAll(RegExp(r' style="[^"]*"'), '')
      .replaceAll(RegExp(r' class="[^"]*"'), '')
      .trim();

  static const _ua =
      'Mozilla/5.0 (Linux; Android 13; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
}
