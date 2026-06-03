class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.shelfId,
    required this.status,
    this.notes,
  });

  final String id;
  final String title;
  final String author;
  final String category;
  final String shelfId;
  final BookStatus status;
  final String? notes;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    String? shelfId,
    BookStatus? status,
    String? notes,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      shelfId: shelfId ?? this.shelfId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

enum BookStatus {
  owned('Owned'),
  wishlist('Wishlist'),
  lent('Lent');

  const BookStatus(this.label);

  final String label;
}
