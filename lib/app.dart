import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class RuangBacaApp extends StatelessWidget {
  const RuangBacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruang Baca',
      theme: AppTheme.light(),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
