import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/reading_progress.dart';

/// Dialog quick-update halaman saat ini. Mengembalikan nomor halaman baru,
/// atau null bila dibatalkan.
Future<int?> showUpdatePageDialog(
  BuildContext context,
  ReadingProgress progress,
) {
  return showDialog<int>(
    context: context,
    builder: (_) => _UpdatePageDialog(progress: progress),
  );
}

class _UpdatePageDialog extends StatefulWidget {
  const _UpdatePageDialog({required this.progress});

  final ReadingProgress progress;

  @override
  State<_UpdatePageDialog> createState() => _UpdatePageDialogState();
}

class _UpdatePageDialogState extends State<_UpdatePageDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.progress.currentPage.toString(),
  );
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      setState(() => _errorText = 'Masukkan angka yang valid');
      return;
    }
    if (value > widget.progress.totalPages) {
      setState(
        () => _errorText = 'Maksimal ${widget.progress.totalPages} halaman',
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.progress.bookTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Halaman saat ini',
          helperText: 'dari ${widget.progress.totalPages} halaman',
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
