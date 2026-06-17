import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/open_library_service.dart';
import '../../data/models/review.dart';
import '../../data/repositories/community_repository.dart';

class CreateReviewPage extends StatefulWidget {
  const CreateReviewPage({super.key, this.existingReview});
  final Review? existingReview;

  @override
  State<CreateReviewPage> createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends State<CreateReviewPage> {
  final _repo = CommunityRepository();
  final _bodyCtrl = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  OpenLibraryBook? _selectedBook;

  bool get _isEdit => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _bodyCtrl.text = widget.existingReview!.body;
      _rating = widget.existingReview!.rating;
    }
  }

  @override
  void dispose() { _bodyCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_rating == 0 || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi rating dan ulasan')));
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
        await _repo.updateReview(widget.existingReview!.copyWith(
          rating: _rating, body: _bodyCtrl.text.trim(), updatedAt: DateTime.now()));
      } else {
        final me = AuthService.instance;
        await _repo.createReview(Review(
          id: '', bookId: _selectedBook!.id, bookTitle: _selectedBook!.title,
          bookThumbnail: _selectedBook!.thumbnailUrl,
          userId: me.uid, userName: me.displayName,
          rating: _rating, body: _bodyCtrl.text.trim(), createdAt: DateTime.now()));
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Ulasan' : 'Tulis Ulasan')),
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
            subtitle: Text(_selectedBook!.authorsText, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedBook = null)))),
          const SizedBox(height: 20),
        ] else ...[
          Card(child: ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: widget.existingReview!.bookThumbnail != null
                ? CachedNetworkImage(imageUrl: widget.existingReview!.bookThumbnail!, width: 40, height: 56, fit: BoxFit.cover)
                : Container(width: 40, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.menu_book))),
            title: Text(widget.existingReview!.bookTitle))),
          const SizedBox(height: 20),
        ],
        Text('Rating', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 40))))),
        const SizedBox(height: 20),
        Text('Ulasan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(controller: _bodyCtrl, maxLines: 5,
          decoration: const InputDecoration(hintText: 'Tulis ulasan tentang buku ini...', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded),
          label: Text(_isEdit ? 'Simpan Perubahan' : 'Kirim Ulasan'),
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
  final _searchCtrl = TextEditingController();
  final _service = OpenLibraryService();
  List<OpenLibraryBook> _results = [];
  bool _loading = false;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try { _results = await _service.searchBooks(_searchCtrl.text.trim()); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _searchCtrl, autofocus: true,
        decoration: const InputDecoration(hintText: 'Cari judul buku...', border: InputBorder.none, filled: false),
        onSubmitted: (_) => _search()),
        actions: [IconButton(onPressed: _search, icon: const Icon(Icons.search))]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _results.isEmpty ? const Center(child: Text('Cari buku untuk diulas', style: TextStyle(color: Colors.grey)))
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
              subtitle: Text(book.authorsText, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(context, book)));
          }),
    );
  }
}
