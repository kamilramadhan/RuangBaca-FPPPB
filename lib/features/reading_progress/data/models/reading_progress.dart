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

  /// Serialisasi untuk Firestore. `id` tidak disimpan di body (dipakai sebagai
  /// doc id). `DateTime` disimpan sebagai milliseconds epoch agar tidak perlu
  /// import `Timestamp` di model.
  Map<String, dynamic> toMap() {
    return {
      'bookTitle': bookTitle,
      'author': author,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'bookId': bookId,
    };
  }

  factory ReadingProgress.fromMap(String id, Map<String, Object?> map) {
    int toInt(Object? v) => v is num ? v.toInt() : 0;
    DateTime toDate(Object? v) =>
        DateTime.fromMillisecondsSinceEpoch(toInt(v));
    return ReadingProgress(
      id: id,
      bookTitle: (map['bookTitle'] as String?) ?? '',
      author: map['author'] as String?,
      currentPage: toInt(map['currentPage']),
      totalPages: toInt(map['totalPages']),
      startedAt: toDate(map['startedAt']),
      updatedAt: toDate(map['updatedAt']),
      bookId: map['bookId'] as String?,
    );
  }

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
