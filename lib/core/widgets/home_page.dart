import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../services/open_library_service.dart';
import '../theme/app_theme.dart';
import 'app_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onSwitchTab});
  final ValueChanged<int>? onSwitchTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OpenLibraryService _booksService = OpenLibraryService();
  List<OpenLibraryBook> _trendingBooks = [];
  List<OpenLibraryBook> _recommendedBooks = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadBooks(); }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _booksService.getTrending(subject: 'fiction', limit: 8),
        _booksService.getTrending(subject: 'education', limit: 6),
      ]);
      if (mounted) setState(() { _trendingBooks = results[0]; _recommendedBooks = results[1]; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(onRefresh: _loadBooks, child: CustomScrollView(slivers: [
        // Header
        SliverToBoxAdapter(child: AppHeader(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeaderTitle(
              title: 'Halo, Pembaca! 👋',
              subtitle: 'Temukan buku favoritmu hari ini',
              trailing: const AppHeaderAction(icon: Icons.auto_stories_rounded),
            ),
            const SizedBox(height: 20),
            GestureDetector(onTap: () => _openSearch(context),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: const Row(children: [Icon(Icons.search, color: Colors.white70), SizedBox(width: 10),
                  Text('Cari buku, penulis...', style: TextStyle(color: Colors.white70))]))),
          ],
        ))),
        // Divider
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Divider(thickness: 1))),
        // Feature Cards
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Expanded(child: _FeatureCard(icon: Icons.menu_book_rounded, title: 'Koleksi\nBuku', subtitle: 'Kelola rak bukumu',
            color: const Color(0xFF1B4965), onTap: () => widget.onSwitchTab?.call(1))),
          const SizedBox(width: 12),
          Expanded(child: _FeatureCard(icon: Icons.forum_rounded, title: 'Diskusi\nKomunitas', subtitle: 'Review & diskusi',
            color: const Color(0xFF5FA8D3), onTap: () => widget.onSwitchTab?.call(3))),
        ]))),
        // Trending
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text('📚 Buku Populer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)))),
        SliverToBoxAdapter(child: SizedBox(height: 200, child: _isLoading ? _buildShimmerList()
          : ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trendingBooks.length, separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _BookCard(book: _trendingBooks[i])))),
        // Rekomendasi
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('🎓 Rekomendasi Edukasi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)))),
        SliverToBoxAdapter(child: SizedBox(height: 200, child: _isLoading ? _buildShimmerList()
          : ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recommendedBooks.length, separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _BookCard(book: _recommendedBooks[i])))),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ])));
  }

  Widget _buildShimmerList() {
    return ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4, separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
        child: Container(width: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))));
  }

  void _openSearch(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _SearchPage()));
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon; final String title; final String subtitle; final Color color; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(height: 150, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24)),
        const Spacer(),
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: color, height: 1.3)),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.7))),
      ])));
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});
  final OpenLibraryBook book;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 130, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12),
        child: book.thumbnailUrl != null
          ? CachedNetworkImage(imageUrl: book.thumbnailUrl!, fit: BoxFit.cover, width: 130,
              placeholder: (_, _) => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.menu_book, color: Colors.grey))),
              errorWidget: (_, _, _) => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))))
          : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.menu_book, color: Colors.grey))))),
      const SizedBox(height: 6),
      Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      Text(book.authorsText, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
    ]));
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage();
  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _searchCtrl = TextEditingController();
  final _booksService = OpenLibraryService();
  List<OpenLibraryBook> _results = [];
  bool _loading = false;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try { _results = await _booksService.searchBooks(q); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _searchCtrl, autofocus: true,
        decoration: const InputDecoration(hintText: 'Cari buku...', border: InputBorder.none, filled: false),
        onSubmitted: (_) => _search()),
        actions: [IconButton(onPressed: _search, icon: const Icon(Icons.search))]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _results.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search, size: 64, color: Colors.grey), SizedBox(height: 12),
            Text('Ketik untuk mencari buku', style: TextStyle(color: Colors.grey))]))
        : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _results.length,
          itemBuilder: (context, i) {
            final book = _results[i];
            return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(borderRadius: BorderRadius.circular(8),
                child: book.thumbnailUrl != null
                  ? CachedNetworkImage(imageUrl: book.thumbnailUrl!, width: 50, height: 70, fit: BoxFit.cover)
                  : Container(width: 50, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.menu_book))),
              title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(book.authorsText, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right)));
          }),
    );
  }
}
