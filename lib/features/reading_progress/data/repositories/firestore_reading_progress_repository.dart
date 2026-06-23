import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/reading_progress.dart';
import 'in_memory_reading_progress_repository.dart';
import 'reading_progress_repository.dart';

/// Memilih implementasi repository sesuai ketersediaan Firebase + login.
/// Tanpa login/Firebase → fallback in-memory (dengan seed opsional untuk demo).
class ReadingProgressRepositoryFactory {
  const ReadingProgressRepositoryFactory._();

  static ReadingProgressRepository create({List<ReadingProgress>? seed}) {
    try {
      if (Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser != null) {
        return FirestoreReadingProgressRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        );
      }
    } catch (_) {
      return InMemoryReadingProgressRepository(seed: seed);
    }
    return InMemoryReadingProgressRepository(seed: seed);
  }
}

/// Dilempar saat operasi butuh user login tapi tidak ada.
class ReadingProgressAuthRequiredException implements Exception {
  const ReadingProgressAuthRequiredException();
  @override
  String toString() => 'Reading progress membutuhkan user yang login.';
}

/// Implementasi Firestore. Data per-user: `users/{uid}/readingProgress/{id}`.
class FirestoreReadingProgressRepository implements ReadingProgressRepository {
  const FirestoreReadingProgressRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw const ReadingProgressAuthRequiredException();
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('readingProgress');

  @override
  Future<List<ReadingProgress>> getAll() async {
    final snapshot = await _collection.orderBy('updatedAt', descending: true).get();
    return snapshot.docs
        .map((doc) => ReadingProgress.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<ReadingProgress?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return ReadingProgress.fromMap(doc.id, data);
  }

  @override
  Future<void> create(ReadingProgress progress) async =>
      _collection.doc(progress.id).set(progress.toMap());

  @override
  Future<void> update(ReadingProgress progress) async =>
      _collection.doc(progress.id).update(progress.toMap());

  @override
  Future<void> delete(String id) async => _collection.doc(id).delete();
}
