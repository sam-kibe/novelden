import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/download_job.dart';
import '../../core/database/isar_service.dart';

class DownloadQueueNotifier extends StateNotifier<List<DownloadJob>> {
  final IsarService _db;
  DownloadQueueNotifier(this._db) : super([]);

  void enqueue(DownloadJob job) {
    _db.saveJob(job);
    state = [...state, job];
  }
}

final downloadQueueProvider =
    StateNotifierProvider<DownloadQueueNotifier, List<DownloadJob>>((ref) {
  return DownloadQueueNotifier(ref.watch(isarServiceProvider));
});
