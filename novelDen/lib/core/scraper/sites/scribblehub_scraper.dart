import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/chapter.dart';
import '../base_scraper.dart';
import '../../../shared/utils/delay_util.dart';

class ScribbleHubScraper extends BaseScraper {
  ScribbleHubScraper(super.template);

  @override
  Future<List<String>> fetchChapterList(String novelUrl) async {
    // ScribbleHub uses a "table of contents" endpoint
    final seriesIdMatch = RegExp(r'/series/(\d+)').firstMatch(novelUrl);
    if (seriesIdMatch == null) throw ScrapeException('Could not parse ScribbleHub ID');
    final seriesId = seriesIdMatch.group(1);

    final allChapters = <String>[];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      await DelayUtil.humanDelay();
      final url = 'https://www.scribblehub.com/wp-admin/admin-ajax.php';
      final response = await Dio().post<String>(url, data: {
        'action': 'wi_gettocchp',
        'strSID': seriesId,
        'strmypostid': '0',
        'strFic': 'yes',
        'intstart': ((page - 1) * 15).toString(),
        'intnum': '15',
      });

      final doc = html_parser.parse(response.data ?? '');
      final items = doc.querySelectorAll('.chapter-item a');
      if (items.isEmpty) {
        hasMore = false;
      } else {
        for (final a in items) {
          final href = a.attributes['href'] ?? '';
          if (href.isNotEmpty) allChapters.add(href);
        }
        page++;
        if (items.length < 15) hasMore = false;
      }
    }
    return allChapters;
  }
}
