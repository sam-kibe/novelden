import 'package:isar/isar.dart';

part 'book.g.dart';

enum BookFormat { epub, pdf, mobi, txt }
enum BookCategory { reading, toRead, favorite, finished }

@Collection()
class Book {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String filePath;

  late String title;
  String? author;
  String? series;
  int? seriesIndex;
  String? coverPath;
  String? description;

  @Enumerated(EnumType.name)
  late BookFormat format;

  @Enumerated(EnumType.name)
  BookCategory category = BookCategory.toRead;

  // Reading progress
  int currentPage = 0;
  int totalPages = 0;
  double get progressPercent =>
      totalPages > 0 ? (currentPage / totalPages * 100) : 0.0;

  // For web novels (scraped)
  bool isScraped = false;
  String? sourceUrl;
  String? sourcePlatform;
  int totalChapters = 0;

  DateTime dateAdded = DateTime.now();
  DateTime? lastRead;

  // Tags stored as comma-separated string (Isar limitation workaround)
  String tagsRaw = '';
  List<String> get tags =>
      tagsRaw.isEmpty ? [] : tagsRaw.split(',');
  set tags(List<String> value) => tagsRaw = value.join(',');
}
