import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  final String uid;
  final String displayName;
  final String email;

  String get initials =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';
}

/// Singleton yang membungkus Firebase Auth dengan fallback ke user lokal.
/// Gunakan [AuthService.instance] dari mana saja.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _fallback = AppUser(
    uid: 'user-local',
    displayName: 'Pengguna',
    email: 'user@ruangbaca.app',
  );

  AppUser _fromFirebaseUser(User? u) {
    if (u == null) return _fallback;
    // Akun anonim/baru daftar bisa mengembalikan displayName/email sebagai
    // string kosong (bukan null), jadi `??` saja tidak cukup — cek
    // isNotEmpty juga.
    final name = u.displayName;
    return AppUser(
      uid: u.uid,
      displayName: name != null && name.isNotEmpty ? name : 'Pengguna',
      email: u.email ?? '',
    );
  }

  AppUser get currentUser {
    try {
      return _fromFirebaseUser(FirebaseAuth.instance.currentUser);
    } catch (_) {
      return _fallback;
    }
  }

  /// Stream yang ikut update saat profil berubah (mis. setelah
  /// updateDisplayName saat daftar), bukan cuma saat sign-in/sign-out
  /// seperti [FirebaseAuth.authStateChanges]. Dipakai widget yang harus
  /// reflect perubahan nama/foto secara langsung tanpa rebuild manual.
  Stream<AppUser> get userChanges =>
      FirebaseAuth.instance.userChanges().map(_fromFirebaseUser);

  String get uid => currentUser.uid;
  String get displayName => currentUser.displayName;
  String get email => currentUser.email;
}
