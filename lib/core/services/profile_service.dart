import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk membaca dan memperbarui profil user di Firestore.
/// Data disimpan di koleksi `users/{uid}`.
class ProfileService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference _ref(String uid) =>
      _db.collection('users').doc(uid);

  /// Stream data profil dari Firestore (realtime).
  static Stream<Map<String, dynamic>> watchProfile(String uid) {
    return _ref(uid).snapshots().map((snap) {
      if (!snap.exists) return {};
      return snap.data() as Map<String, dynamic>;
    });
  }

  /// Ambil string base64 foto profil dari Firestore.
  static Future<String?> getPhotoBase64(String uid) async {
    final snap = await _ref(uid).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return data['photoBase64'] as String?;
  }

  /// Simpan perubahan profil: nama + foto base64 ke Firestore & Firebase Auth.
  static Future<void> updateProfile({
    required String uid,
    required String displayName,
    String? photoBase64,
  }) async {
    final Map<String, dynamic> data = {
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (photoBase64 != null) {
      data['photoBase64'] = photoBase64;
    }

    // Update Firestore
    await _ref(uid).set(data, SetOptions(merge: true));

    // Update Firebase Auth display name
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
  }
}
