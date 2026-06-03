/// Model diskusi/thread.
class Discussion {
  const Discussion({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookThumbnail,
    required this.userId,
    required this.userName,
    required this.title,
    required this.body,
    required this.createdAt,
    this.updatedAt,
    this.replyCount = 0,
  });

  final String id;
  final String bookId;
  final String bookTitle;
  final String? bookThumbnail;
  final String userId;
  final String userName;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int replyCount;

  Discussion copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    int? replyCount,
  }) {
    return Discussion(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      bookThumbnail: bookThumbnail,
      userId: userId,
      userName: userName,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyCount: replyCount ?? this.replyCount,
    );
  }
}

/// Model reply dalam diskusi.
class Reply {
  const Reply({
    required this.id,
    required this.userId,
    required this.userName,
    required this.body,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String body;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
