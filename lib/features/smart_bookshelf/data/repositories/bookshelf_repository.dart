import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/book.dart';
import '../models/shelf.dart';

abstract class BookshelfRepository {
  Future<List<Book>> getBooks();
  Future<List<Shelf>> getShelves();
  Future<void> addBook(Book book);
  Future<void> addShelf(Shelf shelf);
  Future<void> updateBook(Book book);
  Future<void> updateShelf(Shelf shelf);
  Future<void> removeBook(String id);
  Future<void> removeShelf(String id);
}

class BookshelfRepositoryFactory {
  const BookshelfRepositoryFactory._();

  static BookshelfRepository create() {
    try {
      if (Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser != null) {
        return FirestoreBookshelfRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        );
      }
    } catch (_) {
      return InMemoryBookshelfRepository();
    }

    return InMemoryBookshelfRepository();
  }
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
  Future<void> updateBook(Book book) async {
    final index = _books.indexWhere((currentBook) => currentBook.id == book.id);
    if (index != -1) {
      _books[index] = book;
    }
  }

  @override
  Future<void> updateShelf(Shelf shelf) async {
    final index = _shelves.indexWhere(
      (currentShelf) => currentShelf.id == shelf.id,
    );
    if (index != -1) {
      _shelves[index] = shelf;
    }
  }

  @override
  Future<void> removeBook(String id) async {
    _books.removeWhere((book) => book.id == id);
  }

  @override
  Future<void> removeShelf(String id) async {
    _shelves.removeWhere((shelf) => shelf.id == id);
    for (var index = 0; index < _books.length; index++) {
      if (_books[index].shelfId == id) {
        _books[index] = _books[index].copyWith(shelfId: 'main');
      }
    }
  }
}

class FirestoreBookshelfRepository implements BookshelfRepository {
  const FirestoreBookshelfRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _booksCollection {
    return _userCollection.collection('books');
  }

  CollectionReference<Map<String, dynamic>> get _shelvesCollection {
    return _userCollection.collection('shelves');
  }

  DocumentReference<Map<String, dynamic>> get _userCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw const BookshelfAuthRequiredException();
    }

    return _firestore.collection('users').doc(user.uid);
  }

  @override
  Future<List<Book>> getBooks() async {
    final snapshot = await _booksCollection.orderBy('title').get();

    return snapshot.docs
        .map((doc) => Book.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<List<Shelf>> getShelves() async {
    final snapshot = await _shelvesCollection.orderBy('name').get();
    if (snapshot.docs.isEmpty) {
      await _seedDefaultShelves();
      return getShelves();
    }

    return snapshot.docs
        .map((doc) => Shelf.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> addBook(Book book) async {
    await _booksCollection.doc(book.id).set(book.toMap());
  }

  @override
  Future<void> addShelf(Shelf shelf) async {
    await _shelvesCollection.doc(shelf.id).set(shelf.toMap());
  }

  @override
  Future<void> updateBook(Book book) async {
    await _booksCollection.doc(book.id).update(book.toMap());
  }

  @override
  Future<void> updateShelf(Shelf shelf) async {
    await _shelvesCollection.doc(shelf.id).update(shelf.toMap());
  }

  @override
  Future<void> removeBook(String id) async {
    await _booksCollection.doc(id).delete();
  }

  @override
  Future<void> removeShelf(String id) async {
    final batch = _firestore.batch();
    batch.delete(_shelvesCollection.doc(id));

    final booksInShelf = await _booksCollection
        .where('shelfId', isEqualTo: id)
        .get();
    for (final doc in booksInShelf.docs) {
      batch.update(doc.reference, {'shelfId': 'main'});
    }

    await batch.commit();
  }

  Future<void> _seedDefaultShelves() async {
    final batch = _firestore.batch();
    for (final shelf in InMemoryBookshelfRepository()._shelves) {
      batch.set(_shelvesCollection.doc(shelf.id), shelf.toMap());
    }
    await batch.commit();
  }
}

class BookshelfAuthRequiredException implements Exception {
  const BookshelfAuthRequiredException();
}
