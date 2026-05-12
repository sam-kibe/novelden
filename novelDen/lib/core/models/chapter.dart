class ScrapedChapter {
  final String title;
  final String content; // cleaned HTML
  final String sourceUrl;
  final int? index;

  const ScrapedChapter({
    required this.title,
    required this.content,
    required this.sourceUrl,
    this.index,
  });
}

class SiteTemplate {
  final String name;
  final String urlPattern;
  final String chapterListSelector;
  final String chapterTitleSelector;
  final String chapterBodySelector;
  final String? nextPageSelector;
  final List<String> stripSelectors;
  final String paginationType; // "list" or "paginated"
  final String? novelTitleSelector;
  final String? novelAuthorSelector;
  final String? novelCoverSelector;

  const SiteTemplate({
    required this.name,
    required this.urlPattern,
    required this.chapterListSelector,
    required this.chapterTitleSelector,
    required this.chapterBodySelector,
    this.nextPageSelector,
    required this.stripSelectors,
    required this.paginationType,
    this.novelTitleSelector,
    this.novelAuthorSelector,
    this.novelCoverSelector,
  });

  factory SiteTemplate.fromJson(Map<String, dynamic> json) {
    return SiteTemplate(
      name: json['name'] as String,
      urlPattern: json['urlPattern'] as String,
      chapterListSelector: json['chapterListSelector'] as String,
      chapterTitleSelector: json['chapterTitleSelector'] as String,
      chapterBodySelector: json['chapterBodySelector'] as String,
      nextPageSelector: json['nextPageSelector'] as String?,
      stripSelectors: List<String>.from(json['stripSelectors'] as List),
      paginationType: json['paginationType'] as String,
      novelTitleSelector: json['novelTitleSelector'] as String?,
      novelAuthorSelector: json['novelAuthorSelector'] as String?,
      novelCoverSelector: json['novelCoverSelector'] as String?,
    );
  }
}
