import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/chapter.dart';
import '../base_scraper.dart';

class RoyalRoadScraper extends BaseScraper {
  RoyalRoadScraper(super.template);

  @override
  Future<List<String>> fetchChapterList(String novelUrl) async {
    // Extract fiction ID from URL: royalroad.com/fiction/12345/slug
    final match = RegExp(r'/fiction/(\d+)').firstMatch(novelUrl);
    if (match == null) throw ScrapeException('Could not parse RoyalRoad ID from $novelUrl');
    final fictionId = match.group(1);

    // RoyalRoad provides chapters on the main page
    final response = await Dio().get<String>(novelUrl);
    final doc = html_parser.parse(response.data ?? '');
    final rows = doc.querySelectorAll('.chapter-row a');

    return rows
        .map((a) => a.attributes['href'] ?? '')
        .where((h) => h.isNotEmpty)
        .map((h) => h.startsWith('http') ? h : 'https://www.royalroad.com$h')
        .toList();
  }
}
