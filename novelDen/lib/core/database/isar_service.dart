import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/book.dart';
import '../models/download_job.dart';

// Overridden in main.dart with the initialized Isar instance
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main()');
});

class IsarService {
  final Isar _isar;
  IsarService(this._isar);

  // Books
  Future<List<Book>> getAllBooks() async {
    return _isar.books.where().sortByTitle().findAll();
  }

  Future<List<Book>> getBooksForCategory(BookCategory category) async {
    return _isar.books.filter().categoryEqualTo(category).findAll();
  }

  Future<void> saveBook(Book book) async {
    await _isar.writeTxn(() => _isar.books.put(book));
  }

  Future<void> deleteBook(Id id) async {
    await _isar.writeTxn(() => _isar.books.delete(id));
  }

  Future<bool> bookExistsByPath(String path) async {
    return (await _isar.books.filter().filePathEqualTo(path).findFirst()) != null;
  }

  // Download Jobs
  Future<List<DownloadJob>> getDownloadJobs() async {
    return _isar.downloadJobs.where().sortByCreatedAt().findAll();
  }

  Future<void> saveJob(DownloadJob job) async {
    await _isar.writeTxn(() => _isar.downloadJobs.put(job));
  }

  Future<void> deleteJob(Id id) async {
    await _isar.writeTxn(() => _isar.downloadJobs.delete(id));
  }

  Stream<List<Book>> watchBooks() {
    return _isar.books.where().watch(fireImmediately: true);
  }

  Stream<List<DownloadJob>> watchJobs() {
    return _isar.downloadJobs.where().watch(fireImmediately: true);
  }
}

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService(ref.watch(isarProvider));
});
