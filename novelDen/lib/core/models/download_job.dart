import 'package:isar/isar.dart';

part 'download_job.g.dart';

enum JobStatus { queued, running, paused, completed, failed }

@Collection()
class DownloadJob {
  Id id = Isar.autoIncrement;

  late String novelUrl;
  late String novelTitle;
  String? author;
  String? platform;
  String? coverUrl;

  @Enumerated(EnumType.name)
  JobStatus status = JobStatus.queued;

  int currentChapter = 0;
  int totalChapters = 0;
  String? errorMessage;

  DateTime createdAt = DateTime.now();
  DateTime? completedAt;

  double get progressPercent =>
      totalChapters > 0 ? (currentChapter / totalChapters * 100) : 0.0;
}
