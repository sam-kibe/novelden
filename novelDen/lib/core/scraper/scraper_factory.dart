import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/chapter.dart';
import 'base_scraper.dart';
import 'sites/generic_scraper.dart';
import 'sites/royalroad_scraper.dart';
import 'sites/scribblehub_scraper.dart';
import 'sites/novelbin_scraper.dart';
import 'sites/novelfire_scraper.dart';
import 'sites/webnovel_scraper.dart';

class SiteConfigStore {
  static List<SiteTemplate>? _cached;

  static Future<List<SiteTemplate>> loadTemplates() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/site_configs/templates.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cached = (json['sites'] as List)
        .map((s) => SiteTemplate.fromJson(s as Map<String, dynamic>))
        .toList();
    return _cached!;
  }

  static Future<SiteTemplate> templateFor(String url) async {
    final templates = await loadTemplates();
    // Skip the last "Generic" catch-all when looking for specific matches
    for (final t in templates.take(templates.length - 1)) {
      if (RegExp(t.urlPattern).hasMatch(url)) return t;
    }
    return templates.last; // Generic fallback
  }
}

class ScraperFactory {
  static BaseScraper create(SiteTemplate template) {
    switch (template.name) {
      case 'RoyalRoad':
        return RoyalRoadScraper(template);
      case 'ScribbleHub':
        return ScribbleHubScraper(template);
      case 'NovelBin':
        return NovelbinScraper(template);
      case 'NovelFire':
        return NovelFireScraper(template);
      case 'WebNovel':
        return WebNovelScraper(template);
      default:
        return GenericScraper(template);
    }
  }
}
