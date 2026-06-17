import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Tidak ada login otomatis lagi — AuthGate menentukan apakah user
  // diarahkan ke LoginPage atau MainShell berdasarkan status login email.
  runApp(const RuangBacaApp());
}
