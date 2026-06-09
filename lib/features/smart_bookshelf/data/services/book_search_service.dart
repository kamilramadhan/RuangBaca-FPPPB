import 'dart:convert';

import 'package:http/http.dart' as http;

class BookSearchResult {
  const BookSearchResult({
    required this.title,
    required this.author,
    required this.category,
  });

  final String title;
  final String author;
  final String category;
}

class BookSearchService {
  const BookSearchService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<BookSearchResult>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    final client = _client ?? http.Client();
    try {
      final uri = Uri.https('openlibrary.org', '/search.json', {
        'q': trimmedQuery,
        'limit': '8',
      });
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw BookSearchException('Open Library gagal merespons.');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = body['docs'] as List<dynamic>? ?? [];

      return docs.map((doc) {
        final map = doc as Map<String, dynamic>;
        final authors = map['author_name'] as List<dynamic>?;
        final subjects = map['subject'] as List<dynamic>?;

        return BookSearchResult(
          title: map['title'] as String? ?? 'Tanpa judul',
          author: authors == null || authors.isEmpty
              ? 'Penulis tidak diketahui'
              : authors.first.toString(),
          category: subjects == null || subjects.isEmpty
              ? 'Umum'
              : subjects.first.toString(),
        );
      }).toList();
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

class BookSearchException implements Exception {
  const BookSearchException(this.message);

  final String message;
}
