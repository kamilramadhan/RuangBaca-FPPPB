import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 30, left: 20, right: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
          child: Column(children: [
            Row(children: [
              Text('Profil Saya', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
            ]),
            const SizedBox(height: 20),
            Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
              child: CircleAvatar(radius: 48, backgroundColor: theme.colorScheme.tertiary,
                child: Text('P', style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 14),
            Text('Pengguna', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('user@ruangbaca.id', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          ]))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text('Pengaturan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('Tentang Aplikasi'), subtitle: const Text('RuangBaca v1.0.0'),
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [Icon(Icons.auto_stories_rounded, color: Color(0xFF1B4965)), SizedBox(width: 10), Text('RuangBaca')]),
              content: const Text("Aplikasi mobile perpustakaan digital untuk membantu pengguna menemukan, mengelola, dan mendiskusikan buku secara lebih interaktif guna meningkatkan minat baca dan literasi digital masyarakat.\n\nSDG's 4 — Quality Education"),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))]))),
        ])))),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }
}
