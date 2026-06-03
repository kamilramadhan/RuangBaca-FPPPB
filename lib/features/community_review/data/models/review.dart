/// Model review buku.
class Review {
  const Review({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookThumbnail,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.body,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final String bookTitle;
  final String? bookThumbnail;
  final String userId;
  final String userName;
  final int rating; // 1-5
  final String body;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review copyWith({
    int? rating,
    String? body,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      bookThumbnail: bookThumbnail,
      userId: userId,
      userName: userName,
      rating: rating ?? this.rating,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
