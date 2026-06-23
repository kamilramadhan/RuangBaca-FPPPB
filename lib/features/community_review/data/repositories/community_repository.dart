import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/discussion.dart';
import '../models/review.dart';

/// Repository Community Review & Discussion — Firestore.
class CommunityRepository {
  static final _db = FirebaseFirestore.instance;
  static final _reviews = _db.collection('reviews');
  static final _discussions = _db.collection('discussions');

  // ═══════════ REVIEWS ═══════════

  Stream<List<Review>> watchAllReviews() {
    return _reviews
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Review.fromDoc).toList());
  }

  Stream<List<Review>> watchReviewsByBook(String bookId) {
    return _reviews
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Review.fromDoc).toList());
  }

  Future<void> createReview(Review review) async {
    await _reviews.add(review.toMap());
  }

  Future<void> updateReview(Review review) async {
    await _reviews.doc(review.id).update(
          review.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  Future<void> deleteReview(String reviewId) async {
    await _reviews.doc(reviewId).delete();
  }

  // ═══════════ DISCUSSIONS ═══════════

  Stream<List<Discussion>> watchAllDiscussions() {
    return _discussions
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Discussion.fromDoc).toList());
  }

  Future<void> createDiscussion(Discussion discussion) async {
    await _discussions.add(discussion.toMap());
  }

  Future<void> updateDiscussion(Discussion discussion) async {
    await _discussions.doc(discussion.id).update(
          discussion.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  Future<void> deleteDiscussion(String discussionId) async {
    // Hapus semua replies dulu
    final replies =
        await _discussions.doc(discussionId).collection('replies').get();
    for (final doc in replies.docs) {
      await doc.reference.delete();
    }
    await _discussions.doc(discussionId).delete();
  }

  // ═══════════ REPLIES ═══════════

  Stream<List<Reply>> watchReplies(String discussionId) {
    return _discussions
        .doc(discussionId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(Reply.fromDoc).toList());
  }

  Future<void> addReply(String discussionId, Reply reply) async {
    await _discussions.doc(discussionId).collection('replies').add(reply.toMap());
    // Update replyCount
    await _discussions.doc(discussionId).update({
      'replyCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteReply(String discussionId, String replyId) async {
    await _discussions
        .doc(discussionId)
        .collection('replies')
        .doc(replyId)
        .delete();
    await _discussions.doc(discussionId).update({
      'replyCount': FieldValue.increment(-1),
    });
  }

  Future<void> updateReply(
      String discussionId, String replyId, String body) async {
    await _discussions
        .doc(discussionId)
        .collection('replies')
        .doc(replyId)
        .update({'body': body, 'updatedAt': Timestamp.now()});
  }
}
