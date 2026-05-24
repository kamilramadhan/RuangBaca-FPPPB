import '../models/book.dart';

abstract class BookshelfRepository {
  Future<List<Book>> getBooks();
  Future<void> addBook(Book book);
  Future<void> removeBook(String id);
}
