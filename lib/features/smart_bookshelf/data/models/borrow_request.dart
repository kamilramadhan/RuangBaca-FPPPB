class BorrowRequest {
  const BorrowRequest({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.ownerId,
    required this.ownerName,
    required this.borrowerId,
    required this.borrowerName,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String bookId;
  final String bookTitle;
  final String ownerId;
  final String ownerName;
  final String borrowerId;
  final String borrowerName;
  final BorrowRequestStatus status;
  final DateTime requestedAt;

  BorrowRequest copyWith({BorrowRequestStatus? status}) {
    return BorrowRequest(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      ownerId: ownerId,
      ownerName: ownerName,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      status: status ?? this.status,
      requestedAt: requestedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  factory BorrowRequest.fromMap(String id, Map<String, Object?> map) {
    return BorrowRequest(
      id: id,
      bookId: map['bookId'] as String? ?? '',
      bookTitle: map['bookTitle'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      borrowerId: map['borrowerId'] as String? ?? '',
      borrowerName: map['borrowerName'] as String? ?? '',
      status: BorrowRequestStatus.fromName(map['status'] as String?),
      requestedAt: DateTime.tryParse(map['requestedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum BorrowRequestStatus {
  pending('Menunggu'),
  approved('Disetujui'),
  rejected('Ditolak'),
  returned('Dikembalikan');

  const BorrowRequestStatus(this.label);

  final String label;

  static BorrowRequestStatus fromName(String? name) {
    return BorrowRequestStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => BorrowRequestStatus.pending,
    );
  }
}
