import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/services/auth_service.dart';
import '../models/book.dart';
import '../models/borrow_request.dart';
import '../models/shelf.dart';

abstract class BookshelfRepository {
  Future<List<Book>> getBooks();
  Future<List<Book>> getAvailableBooks();
  Future<List<Shelf>> getShelves();
  Future<void> addBook(Book book);
  Future<void> addShelf(Shelf shelf);
  Future<void> updateBook(Book book);
  Future<void> updateShelf(Shelf shelf);
  Future<void> removeBook(String id);
  Future<void> removeShelf(String id);

  Future<List<BorrowRequest>> getIncomingRequests();
  Future<List<BorrowRequest>> getOutgoingRequests();
  Future<void> createBorrowRequest(BorrowRequest request);
  Future<void> updateBorrowRequestStatus(
      String requestId, BorrowRequestStatus status);
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

// ── Demo books milik pengguna lain (untuk tab Cari Buku) ────────────────────

const _demoAvailableBooks = [
  Book(
    id: 'demo-avail-1',
    title: 'Sapiens: Riwayat Singkat Umat Manusia',
    author: 'Yuval Noah Harari',
    category: 'Sejarah',
    shelfId: '',
    status: BookStatus.availableToLend,
    ownerId: 'user-demo-a',
  ),
  Book(
    id: 'demo-avail-2',
    title: 'The Alchemist',
    author: 'Paulo Coelho',
    category: 'Novel',
    shelfId: '',
    status: BookStatus.availableToLend,
    ownerId: 'user-demo-b',
  ),
  Book(
    id: 'demo-avail-3',
    title: 'Rich Dad Poor Dad',
    author: 'Robert T. Kiyosaki',
    category: 'Finansial',
    shelfId: '',
    status: BookStatus.availableToLend,
    ownerId: 'user-demo-c',
  ),
];

// ── In-Memory Repository ─────────────────────────────────────────────────────

class InMemoryBookshelfRepository implements BookshelfRepository {
  InMemoryBookshelfRepository()
    : _shelves = [
        const Shelf(
          id: 'main',
          name: 'Rak Pribadi',
          description: 'Koleksi buku yang sudah dimiliki.',
        ),
        const Shelf(
          id: 'lend',
          name: 'Bisa Dipinjam',
          description: 'Buku yang boleh dipinjam user lain.',
        ),
        const Shelf(
          id: 'wishlist',
          name: 'Wishlist',
          description: 'Daftar buku yang ingin dibaca/dimiliki.',
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
          title: 'Filosofi Teras',
          author: 'Henry Manampiring',
          category: 'Nonfiksi',
          shelfId: 'lend',
          status: BookStatus.availableToLend,
        ),
        const Book(
          id: 'book-3',
          title: 'Atomic Habits',
          author: 'James Clear',
          category: 'Pengembangan Diri',
          shelfId: 'wishlist',
          status: BookStatus.wishlist,
          notes: 'Masuk daftar belanja bulan depan.',
        ),
      ],
      _borrowRequests = [
        // Contoh permintaan masuk: 'Budi' mau pinjam 'Filosofi Teras' milik user lokal
        BorrowRequest(
          id: 'req-1',
          bookId: 'book-2',
          bookTitle: 'Filosofi Teras',
          ownerId: 'user-local',
          ownerName: 'Pengguna',
          borrowerId: 'user-demo-b',
          borrowerName: 'Budi',
          status: BorrowRequestStatus.pending,
          requestedAt: DateTime(2025, 6, 1),
        ),
        // Contoh permintaan keluar: user lokal mau pinjam 'Sapiens' dari 'Pengguna A'
        BorrowRequest(
          id: 'req-2',
          bookId: 'demo-avail-1',
          bookTitle: 'Sapiens: Riwayat Singkat Umat Manusia',
          ownerId: 'user-demo-a',
          ownerName: 'Pengguna A',
          borrowerId: 'user-local',
          borrowerName: 'Pengguna',
          status: BorrowRequestStatus.pending,
          requestedAt: DateTime(2025, 6, 2),
        ),
      ];

  final List<Book> _books;
  final List<Shelf> _shelves;
  final List<BorrowRequest> _borrowRequests;

  String get _currentUserId => AuthService.instance.uid;

  @override
  Future<List<Book>> getBooks() async => List.unmodifiable(_books);

  @override
  Future<List<Book>> getAvailableBooks() async =>
      List.unmodifiable(_demoAvailableBooks);

  @override
  Future<List<Shelf>> getShelves() async => List.unmodifiable(_shelves);

  @override
  Future<void> addBook(Book book) async => _books.add(book);

  @override
  Future<void> addShelf(Shelf shelf) async => _shelves.add(shelf);

  @override
  Future<void> updateBook(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i != -1) _books[i] = book;
  }

  @override
  Future<void> updateShelf(Shelf shelf) async {
    final i = _shelves.indexWhere((s) => s.id == shelf.id);
    if (i != -1) _shelves[i] = shelf;
  }

  @override
  Future<void> removeBook(String id) async =>
      _books.removeWhere((b) => b.id == id);

  @override
  Future<void> removeShelf(String id) async {
    _shelves.removeWhere((s) => s.id == id);
    for (var i = 0; i < _books.length; i++) {
      if (_books[i].shelfId == id) {
        _books[i] = _books[i].copyWith(shelfId: 'main');
      }
    }
  }

  @override
  Future<List<BorrowRequest>> getIncomingRequests() async =>
      List.unmodifiable(
          _borrowRequests.where((r) => r.ownerId == _currentUserId));

  @override
  Future<List<BorrowRequest>> getOutgoingRequests() async =>
      List.unmodifiable(
          _borrowRequests.where((r) => r.borrowerId == _currentUserId));

  @override
  Future<void> createBorrowRequest(BorrowRequest request) async =>
      _borrowRequests.add(request);

  @override
  Future<void> updateBorrowRequestStatus(
      String requestId, BorrowRequestStatus status) async {
    final i = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (i != -1) {
      _borrowRequests[i] = _borrowRequests[i].copyWith(status: status);
    }
  }
}

// ── Firestore Repository ─────────────────────────────────────────────────────

class FirestoreBookshelfRepository implements BookshelfRepository {
  const FirestoreBookshelfRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw const BookshelfAuthRequiredException();
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _booksCollection =>
      _firestore.collection('users').doc(_uid).collection('books');

  CollectionReference<Map<String, dynamic>> get _shelvesCollection =>
      _firestore.collection('users').doc(_uid).collection('shelves');

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('borrowRequests');

  @override
  Future<List<Book>> getBooks() async {
    final snapshot = await _booksCollection.orderBy('title').get();
    return snapshot.docs
        .map((doc) => Book.fromMap(doc.id, doc.data(), ownerId: _uid))
        .toList();
  }

  @override
  Future<List<Book>> getAvailableBooks() async {
    final snapshot = await _firestore
        .collectionGroup('books')
        .where('status', isEqualTo: BookStatus.availableToLend.name)
        .get();
    return snapshot.docs.map((doc) {
      // Ekstrak ownerId dari path: users/{uid}/books/{bookId}
      final ownerId = doc.reference.parent.parent?.id;
      return Book.fromMap(doc.id, doc.data(), ownerId: ownerId);
    }).toList();
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
  Future<void> addBook(Book book) async =>
      _booksCollection.doc(book.id).set(book.toMap());

  @override
  Future<void> addShelf(Shelf shelf) async =>
      _shelvesCollection.doc(shelf.id).set(shelf.toMap());

  @override
  Future<void> updateBook(Book book) async =>
      _booksCollection.doc(book.id).update(book.toMap());

  @override
  Future<void> updateShelf(Shelf shelf) async =>
      _shelvesCollection.doc(shelf.id).update(shelf.toMap());

  @override
  Future<void> removeBook(String id) async =>
      _booksCollection.doc(id).delete();

  @override
  Future<void> removeShelf(String id) async {
    final batch = _firestore.batch();
    batch.delete(_shelvesCollection.doc(id));
    final booksInShelf =
        await _booksCollection.where('shelfId', isEqualTo: id).get();
    for (final doc in booksInShelf.docs) {
      batch.update(doc.reference, {'shelfId': 'main'});
    }
    await batch.commit();
  }

  @override
  Future<List<BorrowRequest>> getIncomingRequests() async {
    final snapshot = await _requestsCollection
        .where('ownerId', isEqualTo: _uid)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => BorrowRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<List<BorrowRequest>> getOutgoingRequests() async {
    final snapshot = await _requestsCollection
        .where('borrowerId', isEqualTo: _uid)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => BorrowRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> createBorrowRequest(BorrowRequest request) async =>
      _requestsCollection.doc(request.id).set(request.toMap());

  @override
  Future<void> updateBorrowRequestStatus(
      String requestId, BorrowRequestStatus status) async =>
      _requestsCollection.doc(requestId).update({'status': status.name});

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
