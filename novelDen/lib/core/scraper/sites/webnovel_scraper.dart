import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/chapter.dart';
import '../base_scraper.dart';
import '../../../shared/utils/delay_util.dart';

/// Scraper for webnovel.com (Qidian International)
///
/// ⚠️  IMPORTANT: WebNovel locks premium/VIP chapters. This scraper can only
/// access chapters that are freely available without a subscription.
/// Attempting to scrape locked chapters will return partial content.
///
/// WebNovel uses a JSON API endpoint for chapter content which is more
/// reliable than HTML parsing.
class WebNovelScraper extends BaseScraper {
  WebNovelScraper(super.template);

  // API base — may change; update if scraper breaks
  static const _apiBase = 'https://www.webnovel.com/apiajax';

  @override
  Future<List<String>> fetchChapterList(String novelUrl) async {
    // URL pattern: webnovel.com/book/title_BOOKID or /book/BOOKID
    final bookId = _extractBookId(novelUrl);
    if (bookId == null) {
      throw ScrapeException('Cannot extract book ID from $novelUrl');
    }

    final allChapterIds = <Map<String, String>>[];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      await DelayUtil.humanDelay();

      try {
        final url =
            '$_apiBase/chapter/GetChapterList?bookId=$bookId&pageIndex=$page&_csrfToken=';
        final response = await Dio(BaseOptions(
          headers: {
            'User-Agent': _ua,
            'Referer': 'https://www.webnovel.com/',
            'Accept': 'application/json',
          },
        )).get(url);

        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final code = data['code'] as int? ?? -1;
        if (code != 0) {
          // API rejected — fall back to HTML
          if (page == 1) return _htmlFallback(novelUrl, bookId);
          break;
        }

        final items = (data['data']?['chapterItems'] as List?) ?? [];
        if (items.isEmpty) {
          hasMore = false;
        } else {
          for (final item in items) {
            final chapterId = (item['id'] ?? '').toString();
            final chapterIndex = (item['index'] ?? page).toString();
            if (chapterId.isNotEmpty) {
              allChapterIds.add({'id': chapterId, 'bookId': bookId});
            }
          }
          page++;
        }
      } on DioException {
        if (page == 1) return _htmlFallback(novelUrl, bookId);
        break;
      }
    }

    // Convert IDs to full chapter URLs
    return allChapterIds
        .map((c) =>
            'https://www.webnovel.com/book/${c['bookId']}/${c['id']}')
        .toList();
  }

  @override
  Future<ScrapedChapter> fetchChapter(String url) async {
    await DelayUtil.humanDelay();

    // Try the JSON API first for cleaner text
    final ids = _extractIds(url);
    if (ids != null) {
      try {
        return await _fetchViaApi(ids['bookId']!, ids['chapterId']!, url);
      } catch (_) {
        // Fall through to HTML parsing
      }
    }

    return _fetchViaHtml(url);
  }

  // ─── API-based fetch ────────────────────────────────────────────────────────

  Future<ScrapedChapter> _fetchViaApi(
    String bookId,
    String chapterId,
    String sourceUrl,
  ) async {
    final apiUrl =
        '$_apiBase/chapter/GetContent?bookId=$bookId&chapterId=$chapterId&_csrfToken=';

    final response = await Dio(BaseOptions(
      headers: {'User-Agent': _ua, 'Referer': 'https://www.webnovel.com/'},
    )).get(apiUrl);

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    if ((data['code'] as int? ?? -1) != 0) {
      throw ScrapeException('API returned error code for $sourceUrl');
    }

    final chapterData = data['data']?['chapterInfo'] as Map<String, dynamic>?;
    final chapterName = (chapterData?['chapterName'] as String?) ?? 'Chapter';
    final contents = chapterData?['contents'] as List?;

    if (contents == null || contents.isEmpty) {
      throw ScrapeException('No content in API response for $sourceUrl — may be locked VIP chapter');
    }

    final paragraphs = contents
        .map((c) => '<p>${c['content']}</p>')
        .join('\n');

    return ScrapedChapter(
      title: chapterName,
      content: paragraphs,
      sourceUrl: sourceUrl,
    );
  }

  // ─── HTML fallback ──────────────────────────────────────────────────────────

  Future<ScrapedChapter> _fetchViaHtml(String url) async {
    final response = await Dio(BaseOptions(
      headers: {'User-Agent': _ua, 'Referer': 'https://www.webnovel.com/'},
    )).get<String>(url);

    final doc = html_parser.parse(response.data ?? '');

    for (final sel in [
      '.cha-words .j_locked', '.lock-info', '.vip-info',
      'script', 'style', '.cha-info',
    ]) {
      doc.querySelectorAll(sel).forEach((e) => e.remove());
    }

    final title = doc
            .querySelector('.cha-tit h3, .chapter-title, ._epIt h3')
            ?.text
            .trim() ??
        'Chapter';

    final body = doc.querySelector('.cha-words, .chapter-content, ._1RYa');
    if (body == null) throw ScrapeException('HTML body not found at $url');

    return ScrapedChapter(
      title: title,
      content: _clean(body.innerHtml),
      sourceUrl: url,
    );
  }

  // ─── HTML chapter-list fallback ─────────────────────────────────────────────

  Future<List<String>> _htmlFallback(String novelUrl, String bookId) async {
    final response = await Dio(BaseOptions(
      headers: {'User-Agent': _ua},
    )).get<String>(novelUrl);

    final doc = html_parser.parse(response.data ?? '');
    return doc
        .querySelectorAll('.chapter-item a, ._1ywH a, .chapter-list a')
        .map((a) => a.attributes['href'] ?? '')
        .where((h) => h.isNotEmpty)
        .map((h) =>
            h.startsWith('http') ? h : 'https://www.webnovel.com$h')
        .toList();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String? _extractBookId(String url) {
    // /book/title_12345678901234567  or  /book/12345678901234567
    final match =
        RegExp(r'/book/(?:[^/]+_)?(\d{15,})').firstMatch(url) ??
        RegExp(r'/book/(\d+)').firstMatch(url);
    return match?.group(1);
  }

  Map<String, String>? _extractIds(String url) {
    // webnovel.com/book/BOOKID/CHAPTERID
    final match =
        RegExp(r'/book/(?:[^/]+_)?(\d+)/(\d+)').firstMatch(url);
    if (match == null) return null;
    return {'bookId': match.group(1)!, 'chapterId': match.group(2)!};
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
