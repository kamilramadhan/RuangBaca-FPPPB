import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';

class RuangBacaApp extends StatelessWidget {
  const RuangBacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuangBaca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
