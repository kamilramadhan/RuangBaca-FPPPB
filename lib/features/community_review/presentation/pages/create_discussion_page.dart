import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/open_library_service.dart';
import '../../data/models/discussion.dart';
import '../../data/repositories/community_repository.dart';

class CreateDiscussionPage extends StatefulWidget {
  const CreateDiscussionPage({super.key, this.existingDiscussion});
  final Discussion? existingDiscussion;

  @override
  State<CreateDiscussionPage> createState() => _CreateDiscussionPageState();
}

class _CreateDiscussionPageState extends State<CreateDiscussionPage> {
  final _repo = CommunityRepository();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _saving = false;
  OpenLibraryBook? _selectedBook;

  bool get _isEdit => widget.existingDiscussion != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleCtrl.text = widget.existingDiscussion!.title;
      _bodyCtrl.text = widget.existingDiscussion!.body;
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi diskusi wajib diisi')));
      return;
    }
    if (!_isEdit && _selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih buku terlebih dahulu')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _repo.updateDiscussion(widget.existingDiscussion!.copyWith(
          title: _titleCtrl.text.trim(), body: _bodyCtrl.text.trim(), updatedAt: DateTime.now()));
      } else {
        final me = AuthService.instance;
        await _repo.createDiscussion(Discussion(
          id: '', bookId: _selectedBook!.id, bookTitle: _selectedBook!.title,
          bookThumbnail: _selectedBook!.thumbnailUrl,
          userId: me.uid, userName: me.displayName,
          title: _titleCtrl.text.trim(), body: _bodyCtrl.text.trim(), createdAt: DateTime.now()));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Diskusi' : 'Buat Diskusi Baru')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (!_isEdit) ...[
          Text('Pilih Buku', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_selectedBook == null)
            OutlinedButton.icon(onPressed: () => _openBookSearch(context),
              icon: const Icon(Icons.search), label: const Text('Cari buku dari OpenLibrary'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))
          else Card(child: ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: _selectedBook!.thumbnailUrl != null
                ? CachedNetworkImage(imageUrl: _selectedBook!.thumbnailUrl!, width: 40, height: 56, fit: BoxFit.cover)
                : Container(width: 40, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.menu_book))),
            title: Text(_selectedBook!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_selectedBook!.authorsText),
            trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedBook = null)))),
          const SizedBox(height: 20),
        ] else ...[
          Card(child: ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: widget.existingDiscussion!.bookThumbnail != null
                ? CachedNetworkImage(imageUrl: widget.existingDiscussion!.bookThumbnail!, width: 40, height: 56, fit: BoxFit.cover)
                : Container(width: 40, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.menu_book))),
            title: Text(widget.existingDiscussion!.bookTitle))),
          const SizedBox(height: 20),
        ],
        Text('Judul Diskusi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(controller: _titleCtrl, decoration: const InputDecoration(
          hintText: 'Contoh: Pendapat kalian tentang ending buku ini?', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        Text('Isi Diskusi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(controller: _bodyCtrl, maxLines: 5,
          decoration: const InputDecoration(hintText: 'Tulis topik diskusi...', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded),
          label: Text(_isEdit ? 'Simpan Perubahan' : 'Kirim Diskusi'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14))),
      ]),
    );
  }

  Future<void> _openBookSearch(BuildContext context) async {
    final selected = await Navigator.push<OpenLibraryBook>(context,
      MaterialPageRoute(builder: (_) => const _BookSearchPicker()));
    if (selected != null) setState(() => _selectedBook = selected);
  }
}

class _BookSearchPicker extends StatefulWidget {
  const _BookSearchPicker();
  @override
  State<_BookSearchPicker> createState() => _BookSearchPickerState();
}

class _BookSearchPickerState extends State<_BookSearchPicker> {
  final _ctrl = TextEditingController();
  final _svc = OpenLibraryService();
  List<OpenLibraryBook> _results = [];
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try { _results = await _svc.searchBooks(_ctrl.text.trim()); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _ctrl, autofocus: true,
        decoration: const InputDecoration(hintText: 'Cari judul buku...', border: InputBorder.none, filled: false),
        onSubmitted: (_) => _search()),
        actions: [IconButton(onPressed: _search, icon: const Icon(Icons.search))]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _results.isEmpty ? const Center(child: Text('Cari buku untuk didiskusikan', style: TextStyle(color: Colors.grey)))
        : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _results.length,
          itemBuilder: (_, i) {
            final book = _results[i];
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(borderRadius: BorderRadius.circular(8),
                child: book.thumbnailUrl != null
                  ? CachedNetworkImage(imageUrl: book.thumbnailUrl!, width: 45, height: 64, fit: BoxFit.cover)
                  : Container(width: 45, height: 64, color: Colors.grey.shade200, child: const Icon(Icons.menu_book))),
              title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(book.authorsText),
              onTap: () => Navigator.pop(context, book)));
          }),
    );
  }
}
