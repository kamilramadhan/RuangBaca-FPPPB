class Discussion {
  const Discussion({
    required this.id,
    required this.bookId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String authorId;
  final String title;
  final String body;
  final DateTime createdAt;
}
