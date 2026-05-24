import 'package:flutter/material.dart';

import '../../features/community_review/community_review.dart';
import '../../features/reading_progress/reading_progress.dart';
import '../../features/smart_bookshelf/smart_bookshelf.dart';
import '../widgets/home_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String bookshelf = '/bookshelf';
  static const String readingProgress = '/reading-progress';
  static const String community = '/community';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomePage(),
    bookshelf: (_) => const BookshelfPage(),
    readingProgress: (_) => const ReadingProgressPage(),
    community: (_) => const CommunityPage(),
  };
}
