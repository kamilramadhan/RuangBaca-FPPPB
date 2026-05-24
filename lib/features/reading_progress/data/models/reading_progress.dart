class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    required this.currentPage,
    required this.totalPages,
    required this.updatedAt,
  });

  final String bookId;
  final int currentPage;
  final int totalPages;
  final DateTime updatedAt;

  double get percentage => totalPages == 0 ? 0 : currentPage / totalPages;
}
