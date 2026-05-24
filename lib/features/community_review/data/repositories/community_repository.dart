import '../models/discussion.dart';
import '../models/review.dart';

abstract class CommunityRepository {
  Future<List<Review>> getReviews(String bookId);
  Future<void> postReview(Review review);

  Future<List<Discussion>> getDiscussions(String bookId);
  Future<void> postDiscussion(Discussion discussion);
}
