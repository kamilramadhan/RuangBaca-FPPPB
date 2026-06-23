import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../data/models/review.dart';
import '../../data/models/discussion.dart';
import '../../data/repositories/community_repository.dart';
import 'create_review_page.dart';
import 'create_discussion_page.dart';
import 'discussion_detail_page.dart';

/// Halaman utama Komunitas — Tab: Ulasan | Diskusi
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _repo = CommunityRepository();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(children: [
        AppHeader(
          padding: EdgeInsets.fromLTRB(
              0, MediaQuery.of(context).padding.top + 16, 0, 0),
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AppHeaderTitle(title: 'Komunitas'),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Ulasan Buku'),
                Tab(text: 'Diskusi'),
              ],
            ),
          ]),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // ── Tab 1: Ulasan ──
              StreamBuilder<List<Review>>(
                stream: _repo.watchAllReviews(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Gagal memuat: ${snap.error}'));
                  }
                  final reviews = snap.data ?? [];
                  if (reviews.isEmpty) {
                    return _EmptyState(
                      icon: Icons.rate_review_outlined,
                      message: 'Belum ada ulasan',
                      sub: 'Jadilah yang pertama menulis ulasan!',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: reviews.length,
                    itemBuilder: (_, i) => _ReviewCard(
                      review: reviews[i],
                      repo: _repo,
                    ),
                  );
                },
              ),

              // ── Tab 2: Diskusi ──
              StreamBuilder<List<Discussion>>(
                stream: _repo.watchAllDiscussions(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Gagal memuat: ${snap.error}'));
                  }
                  final discussions = snap.data ?? [];
                  if (discussions.isEmpty) {
                    return _EmptyState(
                      icon: Icons.forum_outlined,
                      message: 'Belum ada diskusi',
                      sub: 'Mulai diskusi tentang buku favoritmu!',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: discussions.length,
                    itemBuilder: (_, i) => _DiscussionCard(
                      discussion: discussions[i],
                      repo: _repo,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onFabPressed(context),
        icon: const Icon(Icons.add),
        label: ListenableBuilder(
          listenable: _tabCtrl,
          builder: (_, _) => Text(
            _tabCtrl.index == 0 ? 'Tulis Ulasan' : 'Buat Diskusi',
          ),
        ),
      ),
    );
  }

  void _onFabPressed(BuildContext context) {
    if (_tabCtrl.index == 0) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CreateReviewPage()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CreateDiscussionPage()));
    }
  }
}

// ── Empty State ──
class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});
  final IconData icon;
  final String message;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Icon(icon, size: 36, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 16),
        Text(message,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(sub,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ]),
    );
  }
}

// ── Review Card ──
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.repo});
  final Review review;
  final CommunityRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = AuthService.instance.uid == review.userId;
    final initial =
        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'P';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Baris atas: avatar + info buku + menu ──
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar user
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              child: Text(initial,
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(_formatDate(review.createdAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey, fontSize: 11)),
                  ]),
            ),
            if (isOwner)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CreateReviewPage(existingReview: review)));
                  } else if (v == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
          ]),
          const SizedBox(height: 12),

          // ── Baris tengah: cover + info buku ──
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Cover buku
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: review.bookThumbnail != null
                  ? CachedNetworkImage(
                      imageUrl: review.bookThumbnail!,
                      width: 48,
                      height: 68,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 48,
                      height: 68,
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      child: Icon(Icons.menu_book,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          size: 20),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.bookTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    // Rating stars
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber.shade600,
                          size: 16,
                        ),
                      ),
                    ),
                  ]),
            ),
          ]),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Isi review ──
          Text(review.body, style: theme.textTheme.bodyMedium),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus ulasan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              repo.deleteReview(review.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Discussion Card ──
class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.discussion, required this.repo});
  final Discussion discussion;
  final CommunityRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = AuthService.instance.uid == discussion.userId;
    final initial = discussion.userName.isNotEmpty
        ? discussion.userName[0].toUpperCase()
        : 'P';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DiscussionDetailPage(discussion: discussion)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Baris atas: avatar + user info + menu ──
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
                child: Text(initial,
                    style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(discussion.userName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(discussion.bookTitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.secondaryColor, fontSize: 11)),
                    ]),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CreateDiscussionPage(
                                  existingDiscussion: discussion)));
                    } else if (v == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
            ]),
            const SizedBox(height: 12),

            // ── Judul & preview diskusi ──
            Text(discussion.title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(discussion.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 12),

            // ── Footer: reply count + tanggal ──
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(children: [
                  Icon(Icons.forum_outlined,
                      size: 13,
                      color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text('${discussion.replyCount} balasan',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
              const Spacer(),
              Text(
                _formatDate(discussion.createdAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey, fontSize: 11),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus diskusi?'),
        content: const Text('Semua balasan juga akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              repo.deleteDiscussion(discussion.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return '${dt.day}/${dt.month}/${dt.year}';
}
