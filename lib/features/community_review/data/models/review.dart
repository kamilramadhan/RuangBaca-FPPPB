class Review {
  const Review({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final int rating;
  final String body;
  final DateTime createdAt;
}
