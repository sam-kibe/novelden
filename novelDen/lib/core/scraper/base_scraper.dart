import 'dart:math';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:logger/logger.dart';

import '../models/chapter.dart';
import '../../shared/utils/delay_util.dart';

class ScrapeException implements Exception {
  final String message;
  const ScrapeException(this.message);
  @override
  String toString() => 'ScrapeException: $message';
}

abstract class BaseScraper {
  final SiteTemplate template;
  late final Dio _http;
  final _log = Logger();

  static const _userAgents = [
    'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
  ];

  BaseScraper(this.template) {
    _http = Dio(BaseOptions(
      headers: {
        'User-Agent': _rotatingUserAgent(),
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      },
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<void> initialize() async {}

  /// Fetch all chapter URLs from the novel's table of contents page.
  Future<List<String>> fetchChapterList(String novelUrl);

  /// Fetch and parse a single chapter.
  Future<ScrapedChapter> fetchChapter(String url) async {
    await DelayUtil.humanDelay();
    _log.d('Fetching: $url');

    try {
      final response = await _http.get<String>(url);
      if (response.statusCode == 403) {
        throw ScrapeException(
          'Access blocked (403). Site may use Cloudflare. Try again later.',
        );
      }
      final doc = html_parser.parse(response.data ?? '');

      // Remove unwanted elements
      for (final sel in template.stripSelectors) {
        try {
          doc.querySelectorAll(sel).forEach((el) => el.remove());
        } catch (_) {}
      }

      final titleEl = _safeQuery(doc, template.chapterTitleSelector);
      final bodyEl  = _safeQuery(doc, template.chapterBodySelector);

      if (bodyEl == null) {
        throw ScrapeException(
          'Body selector "${template.chapterBodySelector}" found nothing at $url',
        );
      }

      return ScrapedChapter(
        title: titleEl?.text.trim() ?? 'Chapter',
        content: _cleanContent(bodyEl.innerHtml),
        sourceUrl: url,
      );
    } on DioException catch (e) {
      throw ScrapeException('Network error for $url: ${e.message}');
    }
  }

  Element? _safeQuery(Document doc, String selector) {
    try {
      return doc.querySelector(selector);
    } catch (_) {
      return null;
    }
  }

  String _cleanContent(String raw) {
    return raw
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r' style="[^"]*"'), '')
        .replaceAll(RegExp(r' class="[^"]*"'), '')
        .replaceAll(RegExp(r'<(span|div)[^>]*>\s*</\1>'), '')
        .trim();
  }

  static String _rotatingUserAgent() {
    return _userAgents[Random().nextInt(_userAgents.length)];
  }
}
