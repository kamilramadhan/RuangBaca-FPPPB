import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenLibraryBook {
  const OpenLibraryBook({
    required this.id,
    required this.title,
    required this.authors,
    this.description = '',
    this.thumbnailUrl,
    this.pageCount = 0,
    this.averageRating = 0,
    this.publishedDate = '',
    this.categories = const [],
  });

  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String? thumbnailUrl;
  final int pageCount;
  final double averageRating;
  final String publishedDate;
  final List<String> categories;

  String get authorsText => authors.join(', ');

  /// Dari hasil search (/search.json)
  factory OpenLibraryBook.fromSearchJson(Map<String, dynamic> doc) {
    final coverId = doc['cover_i'];
    final String? thumb = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
        : null;

    return OpenLibraryBook(
      id: (doc['key'] as String? ?? '').replaceAll('/works/', ''),
      title: doc['title'] as String? ?? 'Untitled',
      authors:
          (doc['author_name'] as List?)?.map((e) => '$e').toList() ??
              ['Unknown'],
      description:
          (doc['first_sentence'] as List?)?.first as String? ?? '',
      thumbnailUrl: thumb,
      pageCount: doc['number_of_pages_median'] as int? ?? 0,
      averageRating:
          (doc['ratings_average'] as num?)?.toDouble() ?? 0.0,
      publishedDate: doc['first_publish_year']?.toString() ?? '',
      categories: (doc['subject'] as List?)
              ?.take(3)
              .map((e) => '$e')
              .toList() ??
          [],
    );
  }

  /// Dari detail works (/works/OL...W.json)
  factory OpenLibraryBook.fromWorksJson(
      String workId, Map<String, dynamic> json) {
    final desc = json['description'];
    final String description = desc is String
        ? desc
        : (desc is Map ? desc['value'] as String? ?? '' : '');

    final covers = json['covers'] as List?;
    final String? thumb = (covers != null && covers.isNotEmpty)
        ? 'https://covers.openlibrary.org/b/id/${covers.first}-M.jpg'
        : null;

    return OpenLibraryBook(
      id: workId,
      title: json['title'] as String? ?? 'Untitled',
      authors: [],
      description: description,
      thumbnailUrl: thumb,
      pageCount: 0,
      averageRating: 0.0,
      publishedDate: '',
      categories: (json['subjects'] as List?)
              ?.take(3)
              .map((e) => '$e')
              .toList() ??
          [],
    );
  }
}

class OpenLibraryService {
  static const _searchBase = 'https://openlibrary.org/search.json';
  static const _worksBase = 'https://openlibrary.org/works';
  static const _coversBase = 'https://covers.openlibrary.org/b/id';

  /// Search buku berdasarkan query
  Future<List<OpenLibraryBook>> searchBooks(String query,
      {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
        '$_searchBase?q=${Uri.encodeComponent(query)}&limit=$limit&fields=key,title,author_name,cover_i,first_publish_year,subject,number_of_pages_median,ratings_average,first_sentence');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = data['docs'] as List? ?? [];
    return docs
        .map((e) =>
            OpenLibraryBook.fromSearchJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Trending / buku populer berdasarkan subject
  Future<List<OpenLibraryBook>> getTrending(
      {String subject = 'fiction', int limit = 10}) async {
    final uri = Uri.parse(
        '$_searchBase?subject=${Uri.encodeComponent(subject)}&sort=rating&limit=$limit&fields=key,title,author_name,cover_i,first_publish_year,subject,number_of_pages_median,ratings_average');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = data['docs'] as List? ?? [];
    return docs
        .map((e) =>
            OpenLibraryBook.fromSearchJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Detail buku berdasarkan work ID
  Future<OpenLibraryBook?> getById(String workId) async {
    final res = await http.get(Uri.parse('$_worksBase/$workId.json'));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return OpenLibraryBook.fromWorksJson(workId, json);
  }

  /// URL cover dengan ukuran: S / M / L
  String getCoverUrl(String coverId, {String size = 'M'}) {
    return '$_coversBase/$coverId-$size.jpg';
  }
}
