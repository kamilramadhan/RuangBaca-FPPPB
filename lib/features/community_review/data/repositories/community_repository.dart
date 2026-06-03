import 'dart:async';

import '../models/discussion.dart';
import '../models/review.dart';

/// Repository Community Review & Discussion — In-memory untuk development.
/// Akan diganti ke Firestore setelah Firebase dikonfigurasi.
class CommunityRepository {
  // ═══════════ In-Memory Storage ═══════════
  static final List<Review> _reviews = [];
  static final List<Discussion> _discussions = [];
  static final Map<String, List<Reply>> _replies = {};

  // Stream controllers
  static final _reviewsCtrl = StreamController<List<Review>>.broadcast();
  static final _discussionsCtrl =
      StreamController<List<Discussion>>.broadcast();
  static final Map<String, StreamController<List<Reply>>> _replyCtrls = {};

  void _notifyReviews() => _reviewsCtrl.add(List.unmodifiable(_reviews));
  void _notifyDiscussions() =>
      _discussionsCtrl.add(List.unmodifiable(_discussions));
  void _notifyReplies(String discussionId) {
    _replyCtrls[discussionId]
        ?.add(List.unmodifiable(_replies[discussionId] ?? []));
  }

  // ═══════════ REVIEWS — CRUD ═══════════

  Stream<List<Review>> watchAllReviews() {
    Future.microtask(() => _notifyReviews());
    return _reviewsCtrl.stream;
  }

  Stream<List<Review>> watchReviewsByBook(String bookId) {
    return watchAllReviews()
        .map((all) => all.where((r) => r.bookId == bookId).toList());
  }

  Future<void> createReview(Review review) async {
    final newReview = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      bookId: review.bookId,
      bookTitle: review.bookTitle,
      bookThumbnail: review.bookThumbnail,
      userId: review.userId,
      userName: review.userName,
      rating: review.rating,
      body: review.body,
      createdAt: review.createdAt,
    );
    _reviews.insert(0, newReview);
    _notifyReviews();
  }

  Future<void> updateReview(Review review) async {
    final idx = _reviews.indexWhere((r) => r.id == review.id);
    if (idx != -1) {
      _reviews[idx] = review.copyWith(updatedAt: DateTime.now());
      _notifyReviews();
    }
  }

  Future<void> deleteReview(String reviewId) async {
    _reviews.removeWhere((r) => r.id == reviewId);
    _notifyReviews();
  }

  // ═══════════ DISCUSSIONS — CRUD ═══════════

  Stream<List<Discussion>> watchAllDiscussions() {
    Future.microtask(() => _notifyDiscussions());
    return _discussionsCtrl.stream;
  }

  Future<void> createDiscussion(Discussion discussion) async {
    final newDisc = Discussion(
      id: 'disc_${DateTime.now().millisecondsSinceEpoch}',
      bookId: discussion.bookId,
      bookTitle: discussion.bookTitle,
      bookThumbnail: discussion.bookThumbnail,
      userId: discussion.userId,
      userName: discussion.userName,
      title: discussion.title,
      body: discussion.body,
      createdAt: discussion.createdAt,
    );
    _discussions.insert(0, newDisc);
    _notifyDiscussions();
  }

  Future<void> updateDiscussion(Discussion discussion) async {
    final idx = _discussions.indexWhere((d) => d.id == discussion.id);
    if (idx != -1) {
      _discussions[idx] = discussion.copyWith(updatedAt: DateTime.now());
      _notifyDiscussions();
    }
  }

  Future<void> deleteDiscussion(String discussionId) async {
    _discussions.removeWhere((d) => d.id == discussionId);
    _replies.remove(discussionId);
    _replyCtrls.remove(discussionId);
    _notifyDiscussions();
  }

  // ═══════════ REPLIES ═══════════

  Stream<List<Reply>> watchReplies(String discussionId) {
    _replyCtrls.putIfAbsent(
        discussionId, () => StreamController<List<Reply>>.broadcast());
    Future.microtask(() => _notifyReplies(discussionId));
    return _replyCtrls[discussionId]!.stream;
  }

  Future<void> addReply(String discussionId, Reply reply) async {
    final newReply = Reply(
      id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
      userId: reply.userId,
      userName: reply.userName,
      body: reply.body,
      createdAt: reply.createdAt,
    );
    _replies.putIfAbsent(discussionId, () => []);
    _replies[discussionId]!.add(newReply);

    final idx = _discussions.indexWhere((d) => d.id == discussionId);
    if (idx != -1) {
      _discussions[idx] = _discussions[idx].copyWith(
        replyCount: (_replies[discussionId]?.length ?? 0),
      );
      _notifyDiscussions();
    }
    _notifyReplies(discussionId);
  }

  Future<void> updateReply(
      String discussionId, String replyId, String body) async {
    final replies = _replies[discussionId];
    if (replies != null) {
      final idx = replies.indexWhere((r) => r.id == replyId);
      if (idx != -1) {
        replies[idx] = Reply(
          id: replies[idx].id,
          userId: replies[idx].userId,
          userName: replies[idx].userName,
          body: body,
          createdAt: replies[idx].createdAt,
          updatedAt: DateTime.now(),
        );
        _notifyReplies(discussionId);
      }
    }
  }

  Future<void> deleteReply(String discussionId, String replyId) async {
    _replies[discussionId]?.removeWhere((r) => r.id == replyId);
    final idx = _discussions.indexWhere((d) => d.id == discussionId);
    if (idx != -1) {
      _discussions[idx] = _discussions[idx].copyWith(
        replyCount: (_replies[discussionId]?.length ?? 0),
      );
      _notifyDiscussions();
    }
    _notifyReplies(discussionId);
  }
}
