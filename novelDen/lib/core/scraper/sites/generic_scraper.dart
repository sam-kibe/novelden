import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/chapter.dart';
import '../base_scraper.dart';

class GenericScraper extends BaseScraper {
  GenericScraper(super.template);

  @override
  Future<List<String>> fetchChapterList(String novelUrl) async {
    final response = await Dio().get<String>(novelUrl);
    final doc = html_parser.parse(response.data ?? '');
    final anchors = doc.querySelectorAll(template.chapterListSelector);
    final base = Uri.parse(novelUrl);

    return anchors
        .map((a) => a.attributes['href'] ?? '')
        .where((href) => href.isNotEmpty)
        .map((href) => href.startsWith('http') ? href : base.resolve(href).toString())
        .toList();
  }
}
