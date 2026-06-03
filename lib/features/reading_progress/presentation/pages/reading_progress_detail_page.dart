import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/reading_progress.dart';
import '../controllers/reading_progress_controller.dart';
import 'reading_progress_form_page.dart';

class ReadingProgressDetailPage extends StatefulWidget {
  const ReadingProgressDetailPage({
    super.key,
    required this.progressId,
    required this.controller,
  });

  final String progressId;
  final ReadingProgressController controller;

  @override
  State<ReadingProgressDetailPage> createState() =>
      _ReadingProgressDetailPageState();
}

class _ReadingProgressDetailPageState
    extends State<ReadingProgressDetailPage> {
  late final TextEditingController _pageInputCtrl;
  bool _saving = false;
  String? _inputError;

  ReadingProgress? get _progress {
    try {
      return widget.controller.items.firstWhere(
        (e) => e.id == widget.progressId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageInputCtrl = TextEditingController(
      text: _progress?.currentPage.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _pageInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    final progress = _progress;
    if (progress == null) return;

    final value = int.tryParse(_pageInputCtrl.text.trim());
    if (value == null || value < 0) {
      setState(() => _inputError = 'Masukkan angka yang valid');
      return;
    }
    if (value > progress.totalPages) {
      setState(
        () => _inputError = 'Maksimal ${progress.totalPages} halaman',
      );
      return;
    }

    setState(() {
      _saving = true;
      _inputError = null;
    });

    await widget.controller.updateCurrentPage(progress, value);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress diperbarui')),
      );
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
    if (confirmed == true && mounted) {
      final nav = Navigator.of(context);
      await widget.controller.deleteProgress(progress.id);
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final progress = _progress;
        if (progress == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Buku tidak ditemukan')),
          );
        }

        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final pct = (progress.percentage * 100).round();

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              progress.bookTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadingProgressFormPage(
                      controller: widget.controller,
                      existing: progress,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Hapus',
                onPressed: () => _confirmDelete(progress),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            children: [
              // Book cover placeholder
              Center(
                child: Container(
                  width: 160,
                  height: 220,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primaryContainer, cs.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          progress.bookTitle.isNotEmpty
                              ? progress.bookTitle[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (progress.isFinished)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Icon(
                              Icons.check_circle,
                              color: cs.onPrimary,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Title & author
              Text(
                progress.bookTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (progress.author != null) ...[
                const SizedBox(height: 4),
                Text(
                  progress.author!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (progress.isFinished) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Selesai dibaca',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Progress ring card
              _ProgressCard(progress: progress, pct: pct),
              const SizedBox(height: 16),

              // Update progress card (only when not finished)
              if (!progress.isFinished) ...[
                _UpdateProgressCard(
                  progress: progress,
                  pageInputCtrl: _pageInputCtrl,
                  inputError: _inputError,
                  saving: _saving,
                  onSave: _saveProgress,
                ),
                const SizedBox(height: 16),
              ],

              // History card
              _HistoryCard(progress: progress),
            ],
          ),
        );
      },
    );
  }
}

// ─── Progress Ring Card ──────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.pct});

  final ReadingProgress progress;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Current Progress',
              style: theme.textTheme.titleLarge?.copyWith(color: cs.primary),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.percentage,
                backgroundColor: cs.surfaceContainerHigh,
                foregroundColor: cs.primary,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'SELESAI',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${progress.currentPage} dari ${progress.totalPages} halaman',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = backgroundColor;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = foregroundColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Update Progress Card ────────────────────────────────────────────────────

class _UpdateProgressCard extends StatelessWidget {
  const _UpdateProgressCard({
    required this.progress,
    required this.pageInputCtrl,
    required this.inputError,
    required this.saving,
    required this.onSave,
  });

  final ReadingProgress progress;
  final TextEditingController pageInputCtrl;
  final String? inputError;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Progress',
            style: theme.textTheme.titleLarge?.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'SAYA SEDANG DI HALAMAN:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: pageInputCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    errorText: inputError,
                    border: const UnderlineInputBorder(),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: cs.outlineVariant,
                        width: 2,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${progress.totalPages}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Simpan Progress'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Card ────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.progress});

  final ReadingProgress progress;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Kemarin';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Build entries dari data yang tersedia, terbaru di atas
    final entries = <({DateTime date, String description, bool isLatest})>[];

    if (progress.isFinished) {
      entries.add((
        date: progress.updatedAt,
        description: 'Selesai dibaca · ${progress.totalPages} halaman',
        isLatest: true,
      ));
    } else if (progress.currentPage > 0) {
      entries.add((
        date: progress.updatedAt,
        description: 'Diperbarui · halaman ${progress.currentPage}',
        isLatest: true,
      ));
    }

    entries.add((
      date: progress.startedAt,
      description: 'Mulai membaca',
      isLatest: false,
    ));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Baca',
            style: theme.textTheme.titleLarge?.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 16),
          ...entries.asMap().entries.map((mapEntry) {
            final i = mapEntry.key;
            final item = mapEntry.value;
            final isLast = i == entries.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.isLatest ? cs.primary : Colors.transparent,
                        border: Border.all(
                          color: item.isLatest ? cs.primary : cs.outline,
                          width: 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 44,
                        color: cs.outlineVariant,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? 0 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(item.date),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
