import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'bookTitle': bookTitle,
        'bookThumbnail': bookThumbnail,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory Review.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookId: d['bookId'] as String? ?? '',
      bookTitle: d['bookTitle'] as String? ?? '',
      bookThumbnail: d['bookThumbnail'] as String?,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? 'Pengguna',
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      body: d['body'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Review copyWith({int? rating, String? body, DateTime? updatedAt}) {
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
