import '../models/reading_progress.dart';

abstract class ReadingProgressRepository {
  Future<List<ReadingProgress>> getAll();
  Future<ReadingProgress?> getByBookId(String bookId);
  Future<void> save(ReadingProgress progress);
}
