import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'app_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser>(
      stream: AuthService.instance.userChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? AuthService.instance.currentUser;
        return _ProfileView(user: user);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = user.initials;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: AppHeader(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 30),
            child: Column(children: [
              const AppHeaderTitle(title: 'Profil Saya'),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.tertiary,
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.displayName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                user.email.isNotEmpty ? user.email : 'Mode lokal',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Pengaturan',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Tentang Aplikasi'),
                  subtitle: const Text('RuangBaca v1.0.0'),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXl)),
                      title: const Row(children: [
                        Icon(Icons.auto_stories_rounded,
                            color: AppTheme.primaryColor),
                        SizedBox(width: 10),
                        Text('RuangBaca'),
                      ]),
                      content: const Text(
                          'Aplikasi mobile perpustakaan digital untuk membantu pengguna menemukan, mengelola, dan mendiskusikan buku secara lebih interaktif guna meningkatkan minat baca dan literasi digital masyarakat.\n\nSDG\'s 4 — Quality Education'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup')),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                  onTap: () => _confirmLogout(context),
                ),
              ]),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: const Text('Keluar?'),
        content: const Text('Kamu perlu masuk lagi untuk mengakses akunmu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
