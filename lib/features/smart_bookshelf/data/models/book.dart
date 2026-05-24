class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String author;
  final String? coverUrl;
}
