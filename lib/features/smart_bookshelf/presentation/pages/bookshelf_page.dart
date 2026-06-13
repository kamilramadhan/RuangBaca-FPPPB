import 'package:flutter/material.dart';

import '../../data/models/book.dart';
import '../../data/models/borrow_request.dart';
import '../../data/models/shelf.dart';
import '../../data/repositories/bookshelf_repository.dart';
import '../../data/services/book_search_service.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage>
    with SingleTickerProviderStateMixin {
  final BookshelfRepository _repository = BookshelfRepositoryFactory.create();
  late final TabController _tabController;

  List<Book> _books = [];
  List<Book> _availableBooks = [];
  List<Shelf> _shelves = [];
  List<BorrowRequest> _incoming = [];
  List<BorrowRequest> _outgoing = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getBooks(),
      _repository.getShelves(),
      _repository.getAvailableBooks(),
      _repository.getIncomingRequests(),
      _repository.getOutgoingRequests(),
    ]);
    if (!mounted) return;
    setState(() {
      _books = results[0] as List<Book>;
      _shelves = results[1] as List<Shelf>;
      _availableBooks = results[2] as List<Book>;
      _incoming = results[3] as List<BorrowRequest>;
      _outgoing = results[4] as List<BorrowRequest>;
      _isLoading = false;
    });
  }

  int get _pendingIncoming =>
      _incoming.where((r) => r.status == BorrowRequestStatus.pending).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Bookshelf'),
        actions: [
          IconButton(
            tooltip: 'Tambah rak',
            onPressed: _showAddShelfSheet,
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Koleksi Saya'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Permintaan'),
                  if (_pendingIncoming > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(_pendingIncoming),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Cari Buku'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _shelves.isEmpty ? null : _showAddBookSheet,
              icon: const Icon(Icons.add),
              label: const Text('Buku'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _MyCollectionTab(
                  books: _books,
                  shelves: _shelves,
                  onRefresh: _load,
                  onEdit: _showEditBookSheet,
                  onDelete: (book) async {
                    await _repository.removeBook(book.id);
                    await _load();
                  },
                  onToggleLend: (book) async {
                    final next = book.status == BookStatus.availableToLend
                        ? book.copyWith(status: BookStatus.owned)
                        : book.copyWith(status: BookStatus.availableToLend);
                    await _repository.updateBook(next);
                    await _load();
                  },
                ),
                _RequestsTab(
                  incoming: _incoming,
                  outgoing: _outgoing,
                  onRefresh: _load,
                  onApprove: (req) => _handleRequest(req, BorrowRequestStatus.approved),
                  onReject: (req) => _handleRequest(req, BorrowRequestStatus.rejected),
                  onMarkReturned: (req) => _handleRequest(req, BorrowRequestStatus.returned),
                ),
                _FindBooksTab(
                  availableBooks: _availableBooks,
                  outgoing: _outgoing,
                  onRequestBorrow: _showBorrowRequestSheet,
                ),
              ],
            ),
    );
  }

  Future<void> _handleRequest(
      BorrowRequest req, BorrowRequestStatus status) async {
    await _repository.updateBorrowRequestStatus(req.id, status);
    if (status == BorrowRequestStatus.approved) {
      final book = _books.firstWhere((b) => b.id == req.bookId,
          orElse: () => _books.first);
      await _repository.updateBook(book.copyWith(status: BookStatus.lent));
    } else if (status == BorrowRequestStatus.returned) {
      final book = _books.firstWhere((b) => b.id == req.bookId,
          orElse: () => _books.first);
      await _repository.updateBook(
          book.copyWith(status: BookStatus.availableToLend));
    }
    await _load();
  }

  void _showAddBookSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookFormSheet(
        shelves: _shelves,
        onSubmit: (book) async {
          Navigator.pop(context);
          await _repository.addBook(book);
          await _load();
        },
      ),
    );
  }

  void _showEditBookSheet(Book book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookFormSheet(
        shelves: _shelves,
        initialBook: book,
        onSubmit: (updated) async {
          Navigator.pop(context);
          await _repository.updateBook(updated);
          await _load();
        },
      ),
    );
  }

  void _showAddShelfSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ShelfFormSheet(
        onSubmit: (shelf) async {
          Navigator.pop(context);
          await _repository.addShelf(shelf);
          await _load();
        },
      ),
    );
  }

  void _showBorrowRequestSheet(Book book) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _BorrowRequestSheet(
        book: book,
        onConfirm: () async {
          Navigator.pop(context);
          final req = BorrowRequest(
            id: 'req-${DateTime.now().microsecondsSinceEpoch}',
            bookId: book.id,
            bookTitle: book.title,
            ownerId: book.id,
            ownerName: 'Pemilik',
            borrowerId: 'user-me',
            borrowerName: 'Saya',
            status: BorrowRequestStatus.pending,
            requestedAt: DateTime.now(),
          );
          await _repository.createBorrowRequest(req);
          await _load();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permintaan pinjam "${book.title}" terkirim.')),
          );
        },
      ),
    );
  }
}

// ── Tab: Koleksi Saya ──────────────────────────────────────────────────────

class _MyCollectionTab extends StatefulWidget {
  const _MyCollectionTab({
    required this.books,
    required this.shelves,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleLend,
  });

  final List<Book> books;
  final List<Shelf> shelves;
  final Future<void> Function() onRefresh;
  final void Function(Book) onEdit;
  final Future<void> Function(Book) onDelete;
  final Future<void> Function(Book) onToggleLend;

  @override
  State<_MyCollectionTab> createState() => _MyCollectionTabState();
}

class _MyCollectionTabState extends State<_MyCollectionTab> {
  final _searchController = TextEditingController();
  BookStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> get _visible {
    final q = _searchController.text.trim().toLowerCase();
    return widget.books.where((b) {
      final matchQ = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q);
      final matchS = _selectedStatus == null || b.status == _selectedStatus;
      return matchQ && matchS;
    }).toList();
  }

  String _shelfName(String id) =>
      widget.shelves.firstWhere((s) => s.id == id,
          orElse: () => const Shelf(id: '', name: 'Tanpa Rak', description: ''))
          .name;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _CollectionSummary(books: widget.books),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Cari judul atau penulis',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _selectedStatus == null,
                  onSelected: (_) => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 6),
                ...BookStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(s.label),
                        selected: _selectedStatus == s,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = s),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Tidak ada buku yang cocok.')),
            )
          else
            ..._visible.map((book) => _BookCard(
                  book: book,
                  shelfName: _shelfName(book.shelfId),
                  onEdit: () => widget.onEdit(book),
                  onDelete: () => widget.onDelete(book),
                  onToggleLend: () => widget.onToggleLend(book),
                )),
        ],
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.books});

  final List<Book> books;

  int _count(BookStatus s) => books.where((b) => b.status == s).length;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: BookStatus.values
              .map((s) => Expanded(
                    child: Column(
                      children: [
                        Text('${_count(s)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700)),
                        Text(s.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onPrimaryContainer)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.shelfName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleLend,
  });

  final Book book;
  final String shelfName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleLend;

  @override
  Widget build(BuildContext context) {
    final canToggleLend = book.status == BookStatus.owned ||
        book.status == BookStatus.availableToLend;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(book.title.isEmpty ? '?' : book.title[0].toUpperCase()),
        ),
        title: Text(book.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _StatusChip(book.status),
                Chip(
                  label: Text(shelfName),
                  avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                ),
              ],
            ),
            if (book.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(book.notes!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
        trailing: PopupMenuButton<_Action>(
          onSelected: (a) {
            switch (a) {
              case _Action.edit:
                onEdit();
              case _Action.delete:
                onDelete();
              case _Action.toggleLend:
                onToggleLend();
            }
          },
          itemBuilder: (_) => [
            if (canToggleLend)
              PopupMenuItem(
                value: _Action.toggleLend,
                child: ListTile(
                  leading: Icon(book.status == BookStatus.availableToLend
                      ? Icons.lock_outline
                      : Icons.share_outlined),
                  title: Text(book.status == BookStatus.availableToLend
                      ? 'Jadikan Pribadi'
                      : 'Izinkan Dipinjam'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: _Action.edit,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _Action.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Hapus'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Action { edit, delete, toggleLend }

// ── Tab: Permintaan ────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.incoming,
    required this.outgoing,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
    required this.onMarkReturned,
  });

  final List<BorrowRequest> incoming;
  final List<BorrowRequest> outgoing;
  final Future<void> Function() onRefresh;
  final Future<void> Function(BorrowRequest) onApprove;
  final Future<void> Function(BorrowRequest) onReject;
  final Future<void> Function(BorrowRequest) onMarkReturned;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Masuk (${incoming.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (incoming.isEmpty)
            const _EmptyHint('Belum ada permintaan pinjam masuk.')
          else
            ...incoming.map((r) => _IncomingRequestCard(
                  request: r,
                  onApprove: () => onApprove(r),
                  onReject: () => onReject(r),
                  onMarkReturned: () => onMarkReturned(r),
                )),
          const SizedBox(height: 20),
          Text('Keluar (${outgoing.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (outgoing.isEmpty)
            const _EmptyHint('Belum ada permintaan pinjam keluar.')
          else
            ...outgoing.map((r) => _OutgoingRequestCard(request: r)),
        ],
      ),
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onMarkReturned,
  });

  final BorrowRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onMarkReturned;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == BorrowRequestStatus.pending;
    final isApproved = request.status == BorrowRequestStatus.approved;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Text(request.borrowerName,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                _StatusChip(null, requestStatus: request.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('Ingin meminjam: ${request.bookTitle}'),
            const SizedBox(height: 8),
            if (isPending)
              Row(
                children: [
                  OutlinedButton(
                      onPressed: onReject, child: const Text('Tolak')),
                  const SizedBox(width: 8),
                  FilledButton(
                      onPressed: onApprove, child: const Text('Setujui')),
                ],
              )
            else if (isApproved)
              FilledButton.tonal(
                  onPressed: onMarkReturned,
                  child: const Text('Tandai Dikembalikan')),
          ],
        ),
      ),
    );
  }
}

class _OutgoingRequestCard extends StatelessWidget {
  const _OutgoingRequestCard({required this.request});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.book_outlined),
        title: Text(request.bookTitle),
        subtitle: Text('Pemilik: ${request.ownerName}'),
        trailing: _StatusChip(null, requestStatus: request.status),
      ),
    );
  }
}

// ── Tab: Cari Buku ─────────────────────────────────────────────────────────

class _FindBooksTab extends StatefulWidget {
  const _FindBooksTab({
    required this.availableBooks,
    required this.outgoing,
    required this.onRequestBorrow,
  });

  final List<Book> availableBooks;
  final List<BorrowRequest> outgoing;
  final void Function(Book) onRequestBorrow;

  @override
  State<_FindBooksTab> createState() => _FindBooksTabState();
}

class _FindBooksTabState extends State<_FindBooksTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> get _visible {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.availableBooks;
    return widget.availableBooks
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q))
        .toList();
  }

  bool _alreadyRequested(String bookId) => widget.outgoing.any(
      (r) =>
          r.bookId == bookId &&
          (r.status == BorrowRequestStatus.pending ||
              r.status == BorrowRequestStatus.approved));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Cari buku yang tersedia',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (_visible.isEmpty)
          const _EmptyHint('Tidak ada buku yang tersedia untuk dipinjam.')
        else
          ..._visible.map((book) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(book.title.isEmpty
                        ? '?'
                        : book.title[0].toUpperCase()),
                  ),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  trailing: _alreadyRequested(book.id)
                      ? const Chip(label: Text('Diminta'))
                      : FilledButton.tonal(
                          onPressed: () => widget.onRequestBorrow(book),
                          child: const Text('Pinjam'),
                        ),
                ),
              )),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.bookStatus, {this.requestStatus});

  final BookStatus? bookStatus;
  final BorrowRequestStatus? requestStatus;

  @override
  Widget build(BuildContext context) {
    final label = bookStatus?.label ?? requestStatus?.label ?? '';
    final color = _color(context);
    return Chip(
      label: Text(label, style: TextStyle(color: color.onColor(context))),
      backgroundColor: color.color(context),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  _ChipColor _color(BuildContext context) {
    if (bookStatus != null) {
      return switch (bookStatus!) {
        BookStatus.owned => _ChipColor.neutral,
        BookStatus.availableToLend => _ChipColor.green,
        BookStatus.lent => _ChipColor.orange,
        BookStatus.borrowed => _ChipColor.blue,
        BookStatus.wishlist => _ChipColor.purple,
      };
    }
    return switch (requestStatus!) {
      BorrowRequestStatus.pending => _ChipColor.orange,
      BorrowRequestStatus.approved => _ChipColor.green,
      BorrowRequestStatus.rejected => _ChipColor.red,
      BorrowRequestStatus.returned => _ChipColor.neutral,
    };
  }
}

enum _ChipColor { neutral, green, orange, blue, purple, red }

extension _ChipColorExt on _ChipColor {
  Color color(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return switch (this) {
      _ChipColor.neutral => s.surfaceContainerHighest,
      _ChipColor.green => Colors.green.shade100,
      _ChipColor.orange => Colors.orange.shade100,
      _ChipColor.blue => Colors.blue.shade100,
      _ChipColor.purple => Colors.purple.shade100,
      _ChipColor.red => Colors.red.shade100,
    };
  }

  Color onColor(BuildContext context) {
    return switch (this) {
      _ChipColor.neutral => Theme.of(context).colorScheme.onSurface,
      _ChipColor.green => Colors.green.shade800,
      _ChipColor.orange => Colors.orange.shade800,
      _ChipColor.blue => Colors.blue.shade800,
      _ChipColor.purple => Colors.purple.shade800,
      _ChipColor.red => Colors.red.shade800,
    };
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
            color: Theme.of(context).colorScheme.onError, fontSize: 11),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline))),
    );
  }
}

// ── Bottom sheets ──────────────────────────────────────────────────────────

class _BookFormSheet extends StatefulWidget {
  const _BookFormSheet({
    required this.shelves,
    required this.onSubmit,
    this.initialBook,
  });

  final List<Shelf> shelves;
  final Book? initialBook;
  final ValueChanged<Book> onSubmit;

  @override
  State<_BookFormSheet> createState() => _BookFormSheetState();
}

class _BookFormSheetState extends State<_BookFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _searchService = const BookSearchService();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  late String _shelfId;
  BookStatus _status = BookStatus.owned;
  bool _isSearching = false;

  bool get _isEditing => widget.initialBook != null;

  @override
  void initState() {
    super.initState();
    final b = widget.initialBook;
    _titleController.text = b?.title ?? '';
    _authorController.text = b?.author ?? '';
    _categoryController.text = b?.category ?? '';
    _notesController.text = b?.notes ?? '';
    _shelfId = b?.shelfId ?? widget.shelves.first.id;
    _status = b?.status ?? BookStatus.owned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isEditing ? 'Edit Buku' : 'Tambah Buku',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Judul', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isSearching ? null : _searchOpenLibrary,
                  icon: _isSearching
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.travel_explore_outlined),
                  label: const Text('Cari di Open Library'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                      labelText: 'Penulis', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                      labelText: 'Kategori', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BookStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                      labelText: 'Status', border: OutlineInputBorder()),
                  items: BookStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _status = s);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _shelfId,
                  decoration: const InputDecoration(
                      labelText: 'Rak', border: OutlineInputBorder()),
                  items: widget.shelves
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _shelfId = s);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                      labelText: 'Catatan', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_isEditing ? 'Perbarui' : 'Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(Book(
      id: widget.initialBook?.id ??
          'book-${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      category: _categoryController.text.trim(),
      shelfId: _shelfId,
      status: _status,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ));
  }

  Future<void> _searchOpenLibrary() async {
    setState(() => _isSearching = true);
    try {
      final results = await _searchService.search(_titleController.text);
      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buku tidak ditemukan.')));
        return;
      }
      final selected = await showDialog<BookSearchResult>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Pilih Buku'),
          children: results
              .map((r) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(r.author),
                        Text(r.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ))
              .toList(),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() {
        _titleController.text = selected.title;
        _authorController.text = selected.author;
        _categoryController.text = selected.category;
      });
    } on BookSearchException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }
}

class _ShelfFormSheet extends StatefulWidget {
  const _ShelfFormSheet({required this.onSubmit});

  final ValueChanged<Shelf> onSubmit;

  @override
  State<_ShelfFormSheet> createState() => _ShelfFormSheetState();
}

class _ShelfFormSheetState extends State<_ShelfFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tambah Rak', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Nama rak', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  widget.onSubmit(Shelf(
                    id: 'shelf-${DateTime.now().microsecondsSinceEpoch}',
                    name: _nameController.text.trim(),
                    description: _descController.text.trim(),
                  ));
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan Rak'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BorrowRequestSheet extends StatelessWidget {
  const _BorrowRequestSheet({required this.book, required this.onConfirm});

  final Book book;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pinjam Buku', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Kirim permintaan pinjam untuk:'),
            const SizedBox(height: 4),
            Text(book.title,
                style: Theme.of(context).textTheme.titleMedium),
            Text(book.author),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                const SizedBox(width: 12),
                FilledButton(
                    onPressed: onConfirm,
                    child: const Text('Kirim Permintaan')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
