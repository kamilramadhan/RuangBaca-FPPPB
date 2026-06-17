import 'package:flutter/material.dart';

import '../../../../core/widgets/app_header.dart';
import '../../data/models/reading_progress.dart';
import '../../data/repositories/in_memory_reading_progress_repository.dart';
import '../controllers/reading_progress_controller.dart';
import '../widgets/reading_progress_card.dart';
import '../widgets/update_page_dialog.dart';
import 'reading_progress_form_page.dart';

/// Halaman utama Reading Progress Tracker: menampilkan reading history dan
/// menjadi titik masuk semua aksi CRUD.
class ReadingProgressPage extends StatefulWidget {
  const ReadingProgressPage({super.key});

  @override
  State<ReadingProgressPage> createState() => _ReadingProgressPageState();
}

class _ReadingProgressPageState extends State<ReadingProgressPage> {
  // Repository in-memory + data contoh. Ganti ke implementasi persisten nanti.
  late final ReadingProgressController _controller = ReadingProgressController(
    InMemoryReadingProgressRepository(seed: _seedData()),
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  Future<void> _quickUpdatePage(ReadingProgress progress) async {
    final newPage = await showUpdatePageDialog(context, progress);
    if (newPage != null) {
      await _controller.updateCurrentPage(progress, newPage);
    }
  }

  Future<void> _confirmDelete(ReadingProgress progress) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus progress?'),
        content: Text('Hapus "${progress.bookTitle}" dari riwayat baca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteProgress(progress.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            child: const AppHeaderTitle(title: 'Reading Progress'),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    children: [
                      _SummaryHeader(
                        inProgress: _controller.inProgressCount,
                        finished: _controller.finishedCount,
                      ),
                      for (final progress in _controller.items)
                        ReadingProgressCard(
                          progress: progress,
                          onTap: () => _quickUpdatePage(progress),
                          onUpdatePage: () => _quickUpdatePage(progress),
                          onEdit: () => _openForm(existing: progress),
                          onDelete: () => _confirmDelete(progress),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.inProgress, required this.finished});

  final int inProgress;
  final int finished;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              label: 'Sedang dibaca',
              value: inProgress,
              icon: Icons.auto_stories,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Selesai',
              value: finished,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: theme.textTheme.headlineSmall),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('Belum ada riwayat baca', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tekan tombol Tambah untuk mulai melacak buku.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
