import 'package:flutter/material.dart';

import '../../data/models/reading_progress.dart';

/// Kartu satu entri di halaman history.
class ReadingProgressCard extends StatelessWidget {
  const ReadingProgressCard({
    super.key,
    required this.progress,
    required this.onTap,
    required this.onUpdatePage,
    required this.onEdit,
    required this.onDelete,
  });

  final ReadingProgress progress;
  final VoidCallback onTap;
  final VoidCallback onUpdatePage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentLabel = '${(progress.percentage * 100).round()}%';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.bookTitle,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (progress.author != null)
                          Text(
                            progress.author!,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (progress.isFinished)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Chip(
                        label: Text('Selesai'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'update':
                          onUpdatePage();
                        case 'edit':
                          onEdit();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'update',
                        child: Text('Update halaman'),
                      ),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.percentage,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Halaman ${progress.currentPage} / ${progress.totalPages}  •  $percentLabel',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
