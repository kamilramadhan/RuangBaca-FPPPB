import '../models/reading_progress.dart';

/// Kontrak sumber data Reading Progress.
///
/// Ganti implementasi (in-memory, sqflite, REST, dll) tanpa mengubah UI/controller.
abstract class ReadingProgressRepository {
  /// Semua entri, untuk view reading history.
  Future<List<ReadingProgress>> getAll();

  Future<ReadingProgress?> getById(String id);

  /// Create.
  Future<void> create(ReadingProgress progress);

  /// Update (judul, halaman, dll).
  Future<void> update(ReadingProgress progress);

  /// Delete.
  Future<void> delete(String id);
}
