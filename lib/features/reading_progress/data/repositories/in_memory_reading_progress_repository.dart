import '../models/reading_progress.dart';
import 'reading_progress_repository.dart';

/// Implementasi sementara berbasis memori (data hilang saat app restart).
///
/// Cukup untuk development & demo. Ganti dengan implementasi persisten
/// (sqflite/shared_preferences/REST) saat backend siap — UI tidak perlu berubah.
class InMemoryReadingProgressRepository implements ReadingProgressRepository {
  InMemoryReadingProgressRepository({List<ReadingProgress>? seed})
    : _items = [...?seed];

  final List<ReadingProgress> _items;

  @override
  Future<List<ReadingProgress>> getAll() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<ReadingProgress?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> create(ReadingProgress progress) async {
    _items.add(progress);
  }

  @override
  Future<void> update(ReadingProgress progress) async {
    final index = _items.indexWhere((e) => e.id == progress.id);
    if (index == -1) {
      throw StateError('ReadingProgress ${progress.id} tidak ditemukan');
    }
    _items[index] = progress;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}
