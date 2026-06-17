import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
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
    final theme = Theme.of(context);

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
              tabs: const [
                Tab(text: 'Ulasan Buku'),
                Tab(text: 'Diskusi'),
              ],
            ),
          ]),
        ),
        Expanded(child: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab 1: Ulasan ──
          StreamBuilder<List<Review>>(
            stream: _repo.watchAllReviews(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final reviews = snap.data ?? [];
              if (reviews.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Belum ada ulasan',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Jadilah yang pertama menulis ulasan!',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reviews.length,
                itemBuilder: (_, i) => _ReviewTile(
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
              final discussions = snap.data ?? [];
              if (discussions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.forum_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Belum ada diskusi',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Mulai diskusi tentang buku favoritmu!',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: discussions.length,
                itemBuilder: (_, i) => _DiscussionTile(
                  discussion: discussions[i],
                  repo: _repo,
                ),
              );
            },
          ),
        ],
      )),
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
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CreateReviewPage()));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CreateDiscussionPage()));
    }
  }
}

// ── Review Tile ──
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.repo});
  final Review review;
  final CommunityRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = AuthService.instance.uid;
    final isOwner = currentUid == review.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: buku info + menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: review.bookThumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: review.bookThumbnail!,
                          width: 45,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 45,
                          height: 64,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.menu_book,
                              color: Colors.grey),
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
                      const SizedBox(height: 2),
                      Text('oleh ${review.userName}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateReviewPage(
                                existingReview: review),
                          ),
                        );
                      } else if (v == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                          value: 'delete', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Rating stars
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(review.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
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

// ── Discussion Tile ──
class _DiscussionTile extends StatelessWidget {
  const _DiscussionTile({required this.discussion, required this.repo});
  final Discussion discussion;
  final CommunityRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = AuthService.instance.uid;
    final isOwner = currentUid == discussion.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DiscussionDetailPage(discussion: discussion),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(discussion.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                            '${discussion.bookTitle} • ${discussion.userName}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateDiscussionPage(
                                  existingDiscussion: discussion),
                            ),
                          );
                        } else if (v == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                            value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(discussion.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${discussion.replyCount} balasan',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey)),
                  const Spacer(),
                  Text(
                    '${discussion.createdAt.day}/${discussion.createdAt.month}/${discussion.createdAt.year}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus diskusi?'),
        content: const Text(
            'Semua balasan juga akan dihapus.'),
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
