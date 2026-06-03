import 'package:flutter/material.dart';

import '../../features/community_review/community_review.dart';
import '../../features/reading_progress/reading_progress.dart';
import '../../features/smart_bookshelf/smart_bookshelf.dart';
import '../widgets/app_shell.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String bookshelf = '/bookshelf';
  static const String readingProgress = '/reading-progress';
  static const String community = '/community';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const AppShell(),
    bookshelf: (_) => const BookshelfPage(),
    readingProgress: (_) => const ReadingAnalyticsPage(),
    community: (_) => const CommunityPage(),
  };
}
