import '../models/book.dart';
import '../models/shelf.dart';

abstract class BookshelfRepository {
  Future<List<Book>> getBooks();
  Future<List<Shelf>> getShelves();
  Future<void> addBook(Book book);
  Future<void> addShelf(Shelf shelf);
  Future<void> removeBook(String id);
}

class InMemoryBookshelfRepository implements BookshelfRepository {
  InMemoryBookshelfRepository()
    : _shelves = [
        const Shelf(
          id: 'main',
          name: 'Rak Utama',
          description: 'Koleksi buku yang sudah dimiliki.',
        ),
        const Shelf(
          id: 'wishlist',
          name: 'Incaran',
          description: 'Daftar buku yang ingin dibeli atau dibaca.',
        ),
        const Shelf(
          id: 'lent',
          name: 'Dipinjamkan',
          description: 'Buku yang sedang dipinjam orang lain.',
        ),
      ],
      _books = [
        const Book(
          id: 'book-1',
          title: 'Laut Bercerita',
          author: 'Leila S. Chudori',
          category: 'Novel',
          shelfId: 'main',
          status: BookStatus.owned,
          notes: 'Edisi cetak pribadi.',
        ),
        const Book(
          id: 'book-2',
          title: 'Atomic Habits',
          author: 'James Clear',
          category: 'Pengembangan Diri',
          shelfId: 'wishlist',
          status: BookStatus.wishlist,
          notes: 'Masuk daftar belanja bulan depan.',
        ),
        const Book(
          id: 'book-3',
          title: 'Filosofi Teras',
          author: 'Henry Manampiring',
          category: 'Nonfiksi',
          shelfId: 'lent',
          status: BookStatus.lent,
          notes: 'Dipinjam teman kelas.',
        ),
      ];

  final List<Book> _books;
  final List<Shelf> _shelves;

  @override
  Future<List<Book>> getBooks() async {
    return List.unmodifiable(_books);
  }

  @override
  Future<List<Shelf>> getShelves() async {
    return List.unmodifiable(_shelves);
  }

  @override
  Future<void> addBook(Book book) async {
    _books.add(book);
  }

  @override
  Future<void> addShelf(Shelf shelf) async {
    _shelves.add(shelf);
  }

  @override
  Future<void> removeBook(String id) async {
    _books.removeWhere((book) => book.id == id);
  }
}
