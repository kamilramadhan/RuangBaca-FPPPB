/// Satu entri progress membaca sebuah buku.
///
/// Self-contained: judul & penulis diisi manual di fitur ini. `bookId` opsional
/// untuk menaut ke Smart Bookshelf nanti (cukup pakai ID, jangan import model-nya).
class ReadingProgress {
  const ReadingProgress({
    required this.id,
    required this.bookTitle,
    required this.currentPage,
    required this.totalPages,
    required this.startedAt,
    required this.updatedAt,
    this.author,
    this.bookId,
  });

  final String id;
  final String bookTitle;
  final String? author;
  final int currentPage;
  final int totalPages;
  final DateTime startedAt;
  final DateTime updatedAt;
  final String? bookId;

  /// Progress 0.0–1.0.
  double get percentage =>
      totalPages == 0 ? 0 : (currentPage / totalPages).clamp(0.0, 1.0);

  bool get isFinished => totalPages > 0 && currentPage >= totalPages;

  int get remainingPages => (totalPages - currentPage).clamp(0, totalPages);

  ReadingProgress copyWith({
    String? bookTitle,
    String? author,
    int? currentPage,
    int? totalPages,
    DateTime? updatedAt,
    String? bookId,
  }) {
    return ReadingProgress(
      id: id,
      bookTitle: bookTitle ?? this.bookTitle,
      author: author ?? this.author,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookId: bookId ?? this.bookId,
    );
  }
}
