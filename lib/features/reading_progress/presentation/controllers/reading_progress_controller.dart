import 'package:flutter/foundation.dart';

import '../../data/models/reading_progress.dart';
import '../../data/repositories/reading_progress_repository.dart';

/// State holder untuk Reading Progress. Menjembatani UI dengan repository
/// dan menyimpan daftar entri yang sudah diurutkan untuk view history.
class ReadingProgressController extends ChangeNotifier {
  ReadingProgressController(this._repository);

  final ReadingProgressRepository _repository;

  List<ReadingProgress> _items = const [];
  bool _isLoading = false;
  String? _error;

  /// Entri terurut dari yang paling baru di-update (history terbaru di atas).
  List<ReadingProgress> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => !_isLoading && _items.isEmpty;

  int get finishedCount => _items.where((e) => e.isFinished).length;
  int get inProgressCount => _items.length - finishedCount;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.getAll();
      _items = _sorted(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create reading progress baru.
  Future<void> createProgress({
    required String bookTitle,
    String? author,
    required int currentPage,
    required int totalPages,
    String? bookId,
  }) async {
    final now = DateTime.now();
    final progress = ReadingProgress(
      id: now.microsecondsSinceEpoch.toString(),
      bookTitle: bookTitle.trim(),
      author: _nullIfBlank(author),
      currentPage: currentPage.clamp(0, totalPages),
      totalPages: totalPages,
      startedAt: now,
      updatedAt: now,
      bookId: _nullIfBlank(bookId),
    );
    await _repository.create(progress);
    await load();
  }

  /// Update penuh sebuah entri (mis. dari form edit).
  Future<void> editProgress(
    ReadingProgress original, {
    required String bookTitle,
    String? author,
    required int currentPage,
    required int totalPages,
  }) async {
    final updated = original.copyWith(
      bookTitle: bookTitle.trim(),
      author: _nullIfBlank(author),
      currentPage: currentPage.clamp(0, totalPages),
      totalPages: totalPages,
      updatedAt: DateTime.now(),
    );
    await _repository.update(updated);
    await load();
  }

  /// Update cepat halaman saat ini (quick update dari list).
  Future<void> updateCurrentPage(ReadingProgress progress, int newPage) async {
    final updated = progress.copyWith(
      currentPage: newPage.clamp(0, progress.totalPages),
      updatedAt: DateTime.now(),
    );
    await _repository.update(updated);
    await load();
  }

  /// Tandai selesai (set halaman = total).
  Future<void> markAsFinished(ReadingProgress progress) async {
    await updateCurrentPage(progress, progress.totalPages);
  }

  /// Delete reading progress.
  Future<void> deleteProgress(String id) async {
    await _repository.delete(id);
    await load();
  }

  List<ReadingProgress> _sorted(List<ReadingProgress> data) {
    final list = [...data]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  String? _nullIfBlank(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
