class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.shelfId,
    required this.status,
    this.ownerId,
    this.notes,
  });

  final String id;
  final String title;
  final String author;
  final String category;
  final String shelfId;
  final BookStatus status;
  /// UID pemilik buku. Di Firestore diturunkan dari path koleksi; di InMemory di-set manual.
  final String? ownerId;
  final String? notes;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    String? shelfId,
    BookStatus? status,
    String? ownerId,
    String? notes,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      shelfId: shelfId ?? this.shelfId,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'shelfId': shelfId,
      'status': status.name,
      'notes': notes,
      // ownerId tidak disimpan di dokumen — diturunkan dari path koleksi
    };
  }

  factory Book.fromMap(String id, Map<String, Object?> map, {String? ownerId}) {
    return Book(
      id: id,
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      category: map['category'] as String? ?? '',
      shelfId: map['shelfId'] as String? ?? '',
      status: BookStatus.fromName(map['status'] as String?),
      ownerId: ownerId,
      notes: map['notes'] as String?,
    );
  }
}

enum BookStatus {
  owned('Koleksi Pribadi'),
  availableToLend('Bisa Dipinjam'),
  lent('Sedang Dipinjamkan'),
  borrowed('Sedang Dipinjam'),
  wishlist('Wishlist');

  const BookStatus(this.label);

  final String label;

  static BookStatus fromName(String? name) {
    return BookStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => BookStatus.owned,
    );
  }
}
