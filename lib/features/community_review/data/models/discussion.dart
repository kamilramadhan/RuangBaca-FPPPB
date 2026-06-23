import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'bookTitle': bookTitle,
        'bookThumbnail': bookThumbnail,
        'userId': userId,
        'userName': userName,
        'title': title,
        'body': body,
        'replyCount': replyCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory Discussion.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Discussion(
      id: doc.id,
      bookId: d['bookId'] as String? ?? '',
      bookTitle: d['bookTitle'] as String? ?? '',
      bookThumbnail: d['bookThumbnail'] as String?,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? 'Pengguna',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      replyCount: (d['replyCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

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

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory Reply.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Reply(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? 'Pengguna',
      body: d['body'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
