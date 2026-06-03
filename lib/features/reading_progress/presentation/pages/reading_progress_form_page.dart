import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/reading_progress.dart';
import '../controllers/reading_progress_controller.dart';

/// Form create / edit reading progress.
/// Lewatkan [existing] untuk mode edit; null = mode create.
class ReadingProgressFormPage extends StatefulWidget {
  const ReadingProgressFormPage({
    super.key,
    required this.controller,
    this.existing,
  });

  final ReadingProgressController controller;
  final ReadingProgress? existing;

  bool get isEdit => existing != null;

  @override
  State<ReadingProgressFormPage> createState() =>
      _ReadingProgressFormPageState();
}

class _ReadingProgressFormPageState extends State<ReadingProgressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _currentPageCtrl;
  late final TextEditingController _totalPagesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.bookTitle ?? '');
    _authorCtrl = TextEditingController(text: e?.author ?? '');
    _currentPageCtrl = TextEditingController(
      text: e == null ? '0' : e.currentPage.toString(),
    );
    _totalPagesCtrl = TextEditingController(
      text: e == null ? '' : e.totalPages.toString(),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _currentPageCtrl.dispose();
    _totalPagesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();
    final currentPage = int.parse(_currentPageCtrl.text.trim());
    final totalPages = int.parse(_totalPagesCtrl.text.trim());

    try {
      if (widget.isEdit) {
        await widget.controller.editProgress(
          widget.existing!,
          bookTitle: title,
          author: author,
          currentPage: currentPage,
          totalPages: totalPages,
        );
      } else {
        await widget.controller.createProgress(
          bookTitle: title,
          author: author,
          currentPage: currentPage,
          totalPages: totalPages,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateTotalPages(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n <= 0) return 'Total halaman harus lebih dari 0';
    return null;
  }

  String? _validateCurrentPage(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n < 0) return 'Halaman tidak valid';
    final total = int.tryParse(_totalPagesCtrl.text.trim());
    if (total != null && n > total) return 'Tidak boleh melebihi total halaman';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Progress' : 'Tambah Buku'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Judul buku *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Penulis (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currentPageCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Halaman saat ini',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateCurrentPage,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _totalPagesCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Total halaman *',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateTotalPages,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambahkan'),
            ),
          ],
        ),
      ),
    );
  }
}
