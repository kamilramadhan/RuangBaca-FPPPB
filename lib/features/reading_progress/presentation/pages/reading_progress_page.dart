import 'package:flutter/material.dart';

import '../../data/models/reading_progress.dart';
import '../../data/repositories/in_memory_reading_progress_repository.dart';
import '../controllers/reading_progress_controller.dart';
import 'reading_progress_detail_page.dart';
import 'reading_progress_form_page.dart';

class ReadingAnalyticsPage extends StatefulWidget {
  const ReadingAnalyticsPage({super.key});

  @override
  State<ReadingAnalyticsPage> createState() => _ReadingAnalyticsPageState();
}

class _ReadingAnalyticsPageState extends State<ReadingAnalyticsPage> {
  late final ReadingProgressController _controller = ReadingProgressController(
    InMemoryReadingProgressRepository(seed: _seedData()),
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _totalPagesRead =>
      _controller.items.fold(0, (sum, e) => sum + e.currentPage);

  Future<void> _openForm({ReadingProgress? existing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingProgressFormPage(
          controller: _controller,
          existing: existing,
        ),
      ),
    );
  }

  void _openDetail(ReadingProgress progress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingProgressDetailPage(
          progressId: progress.id,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final monthLabel = '${months[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: cs.surface,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeReads =
              _controller.items.where((e) => !e.isFinished).toList();
          final finishedReads =
              _controller.items.where((e) => e.isFinished).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                floating: true,
                snap: true,
                elevation: 0,
                title: Text(
                  'Reading Progress',
                  style: theme.textTheme.titleLarge,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Tambah buku',
                    onPressed: () => _openForm(),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Reading Analytics',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Progres Anda untuk $monthLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _StatsBento(
                      totalPages: _totalPagesRead,
                      inProgress: _controller.inProgressCount,
                      finished: _controller.finishedCount,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Sedang Dibaca',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openForm(),
                          child: const Text('+ Tambah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (activeReads.isEmpty)
                      _EmptyActiveState(onAdd: () => _openForm())
                    else
                      ...activeReads.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ActiveReadCard(
                            progress: p,
                            onTap: () => _openDetail(p),
                          ),
                        ),
                      ),
                    if (finishedReads.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Selesai Dibaca',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...finishedReads.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FinishedReadCard(
                            progress: p,
                            onTap: () => _openDetail(p),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static List<ReadingProgress> _seedData() {
    final now = DateTime.now();
    return [
      ReadingProgress(
        id: 'seed-1',
        bookTitle: 'Atomic Habits',
        author: 'James Clear',
        currentPage: 120,
        totalPages: 320,
        startedAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      ReadingProgress(
        id: 'seed-2',
        bookTitle: 'Laskar Pelangi',
        author: 'Andrea Hirata',
        currentPage: 529,
        totalPages: 529,
        startedAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

// ─── Stats Bento ────────────────────────────────────────────────────────────

class _StatsBento extends StatelessWidget {
  const _StatsBento({
    required this.totalPages,
    required this.inProgress,
    required this.finished,
  });

  final int totalPages;
  final int inProgress;
  final int finished;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCard(
                  icon: Icons.menu_book_outlined,
                  value: '$totalPages',
                  label: 'HALAMAN DIBACA',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCard(
                  icon: Icons.auto_stories_outlined,
                  value: '$inProgress',
                  label: 'BUKU AKTIF',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCard(
                  icon: Icons.check_circle_outline,
                  value: '$finished',
                  label: 'BUKU SELESAI',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _HighlightBentoCard(inProgress: inProgress)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightBentoCard extends StatelessWidget {
  const _HighlightBentoCard({required this.inProgress});

  final int inProgress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights, color: cs.onPrimary, size: 28),
          const SizedBox(height: 12),
          Text(
            inProgress > 0 ? 'Pembaca\nAktif!' : 'Mulai\nBaca!',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            inProgress > 0
                ? 'Terus semangat membaca setiap hari.'
                : 'Tambahkan buku pertama Anda.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimary.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active Read Card ────────────────────────────────────────────────────────

class _ActiveReadCard extends StatelessWidget {
  const _ActiveReadCard({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final pct = (progress.percentage * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withAlpha(77)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookCover(title: progress.bookTitle),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.bookTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress.author != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        progress.author!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$pct% Selesai',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${progress.currentPage} / ${progress.totalPages}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.percentage,
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Finished Read Card ──────────────────────────────────────────────────────

class _FinishedReadCard extends StatelessWidget {
  const _FinishedReadCard({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cs.secondaryContainer,
              ),
              child: Center(
                child: Icon(Icons.check_circle, color: cs.secondary, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.bookTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress.author != null)
                    Text(
                      progress.author!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Selesai · ${progress.totalPages} halaman',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyActiveState extends StatelessWidget {
  const _EmptyActiveState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'Belum ada buku yang sedang dibaca',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Buku'),
          ),
        ],
      ),
    );
  }
}

// ─── Book Cover Placeholder ──────────────────────────────────────────────────

class _BookCover extends StatelessWidget {
  const _BookCover({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.primary.withAlpha(180)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: cs.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
