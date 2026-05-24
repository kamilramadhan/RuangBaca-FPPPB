import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruang Baca')),
      body: ListView(
        children: [
          _MenuTile(
            title: 'Smart Bookshelf',
            subtitle: 'Kelola koleksi buku Anda',
            icon: Icons.menu_book,
            route: AppRoutes.bookshelf,
          ),
          _MenuTile(
            title: 'Reading Progress',
            subtitle: 'Pantau progress membaca',
            icon: Icons.show_chart,
            route: AppRoutes.readingProgress,
          ),
          _MenuTile(
            title: 'Community',
            subtitle: 'Review & diskusi buku',
            icon: Icons.forum,
            route: AppRoutes.community,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
