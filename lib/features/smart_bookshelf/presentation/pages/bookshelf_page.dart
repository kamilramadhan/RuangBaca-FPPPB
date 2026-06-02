import 'package:flutter/material.dart';

import '../../data/models/book.dart';
import '../../data/models/shelf.dart';
import '../../data/repositories/bookshelf_repository.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  final BookshelfRepository _repository = InMemoryBookshelfRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  List<Shelf> _shelves = [];
  BookStatus? _selectedStatus;
  String? _selectedShelfId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookshelf();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookshelf() async {
    final books = await _repository.getBooks();
    final shelves = await _repository.getShelves();

    setState(() {
      _books = books;
      _shelves = shelves;
      _isLoading = false;
    });
  }

  List<Book> get _visibleBooks {
    final query = _searchController.text.trim().toLowerCase();

    return _books.where((book) {
      final matchesQuery =
          query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.category.toLowerCase().contains(query);
      final matchesStatus =
          _selectedStatus == null || book.status == _selectedStatus;
      final matchesShelf =
          _selectedShelfId == null || book.shelfId == _selectedShelfId;

      return matchesQuery && matchesStatus && matchesShelf;
    }).toList();
  }

  int _countByStatus(BookStatus status) {
    return _books.where((book) => book.status == status).length;
  }

  String _shelfName(String shelfId) {
    for (final shelf in _shelves) {
      if (shelf.id == shelfId) {
        return shelf.name;
      }
    }

    return 'Tanpa rak';
  }

  Future<void> _addBook(Book book) async {
    await _repository.addBook(book);
    await _loadBookshelf();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${book.title} ditambahkan ke rak.')),
    );
  }

  Future<void> _addShelf(Shelf shelf) async {
    await _repository.addShelf(shelf);
    await _loadBookshelf();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rak ${shelf.name} berhasil dibuat.')),
    );
  }

  Future<void> _removeBook(Book book) async {
    await _repository.removeBook(book.id);
    await _loadBookshelf();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${book.title} dihapus dari koleksi.')),
    );
  }

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shelves.isEmpty ? null : _showAddBookSheet,
        icon: const Icon(Icons.add),
        label: const Text('Buku'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookshelf,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  _BookshelfSummary(
                    totalBooks: _books.length,
                    ownedBooks: _countByStatus(BookStatus.owned),
                    wishlistBooks: _countByStatus(BookStatus.wishlist),
                    lentBooks: _countByStatus(BookStatus.lent),
                  ),
                  const SizedBox(height: 16),
                  _SearchAndFilters(
                    searchController: _searchController,
                    shelves: _shelves,
                    selectedStatus: _selectedStatus,
                    selectedShelfId: _selectedShelfId,
                    onStatusChanged: (status) {
                      setState(() => _selectedStatus = status);
                    },
                    onShelfChanged: (shelfId) {
                      setState(() => _selectedShelfId = shelfId);
                    },
                    onClearFilters: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedShelfId = null;
                        _searchController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _ShelfSection(shelves: _shelves, books: _books),
                  const SizedBox(height: 16),
                  Text(
                    'Koleksi Buku',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_visibleBooks.isEmpty)
                    const _EmptyBookshelf()
                  else
                    ..._visibleBooks.map(
                      (book) => _BookCard(
                        book: book,
                        shelfName: _shelfName(book.shelfId),
                        onDelete: () => _removeBook(book),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _showAddBookSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _AddBookSheet(
          shelves: _shelves,
          onSubmit: (book) {
            Navigator.pop(context);
            _addBook(book);
          },
        );
      },
    );
  }

  void _showAddShelfSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _AddShelfSheet(
          onSubmit: (shelf) {
            Navigator.pop(context);
            _addShelf(shelf);
          },
        );
      },
    );
  }
}

class _BookshelfSummary extends StatelessWidget {
  const _BookshelfSummary({
    required this.totalBooks,
    required this.ownedBooks,
    required this.wishlistBooks,
    required this.lentBooks,
  });

  final int totalBooks;
  final int ownedBooks;
  final int wishlistBooks;
  final int lentBooks;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Rak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(label: 'Total', value: totalBooks),
                ),
                Expanded(
                  child: _MetricTile(label: 'Owned', value: ownedBooks),
                ),
                Expanded(
                  child: _MetricTile(label: 'Wishlist', value: wishlistBooks),
                ),
                Expanded(
                  child: _MetricTile(label: 'Lent', value: lentBooks),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.searchController,
    required this.shelves,
    required this.selectedStatus,
    required this.selectedShelfId,
    required this.onStatusChanged,
    required this.onShelfChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final List<Shelf> shelves;
  final BookStatus? selectedStatus;
  final String? selectedShelfId;
  final ValueChanged<BookStatus?> onStatusChanged;
  final ValueChanged<String?> onShelfChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Cari judul, penulis, atau kategori',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: const Text('Semua status'),
              selected: selectedStatus == null,
              onSelected: (_) => onStatusChanged(null),
            ),
            ...BookStatus.values.map(
              (status) => FilterChip(
                label: Text(status.label),
                selected: selectedStatus == status,
                onSelected: (_) => onStatusChanged(status),
              ),
            ),
            PopupMenuButton<String?>(
              tooltip: 'Pilih rak',
              onSelected: onShelfChanged,
              itemBuilder: (context) => [
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text('Semua rak'),
                ),
                ...shelves.map(
                  (shelf) => PopupMenuItem<String?>(
                    value: shelf.id,
                    child: Text(shelf.name),
                  ),
                ),
              ],
              child: InputChip(
                avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text(
                  selectedShelfId == null
                      ? 'Semua rak'
                      : shelves
                            .firstWhere((shelf) => shelf.id == selectedShelfId)
                            .name,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.close),
              label: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShelfSection extends StatelessWidget {
  const _ShelfSection({required this.shelves, required this.books});

  final List<Shelf> shelves;
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rak Custom', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shelves.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final shelf = shelves[index];
              final count = books
                  .where((book) => book.shelfId == shelf.id)
                  .length;

              return SizedBox(
                width: 220,
                child: Material(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.folder_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shelf.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shelf.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text('$count buku'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.shelfName,
    required this.onDelete,
  });

  final Book book;
  final String shelfName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(book.status.label),
                  avatar: const Icon(Icons.bookmark_outline, size: 18),
                ),
                Chip(
                  label: Text(book.category),
                  avatar: const Icon(Icons.category_outlined, size: 18),
                ),
                Chip(
                  label: Text(shelfName),
                  avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                ),
              ],
            ),
            if (book.notes case final notes?)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(notes),
              ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Hapus buku',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _EmptyBookshelf extends StatelessWidget {
  const _EmptyBookshelf();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text('Belum ada buku yang cocok.'),
          ],
        ),
      ),
    );
  }
}

class _AddBookSheet extends StatefulWidget {
  const _AddBookSheet({required this.shelves, required this.onSubmit});

  final List<Shelf> shelves;
  final ValueChanged<Book> onSubmit;

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  late String _shelfId = widget.shelves.first.id;
  BookStatus _status = BookStatus.owned;

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
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tambah Buku',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Penulis',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BookStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: BookStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status != null) {
                      setState(() => _status = status);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _shelfId,
                  decoration: const InputDecoration(
                    labelText: 'Rak',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.shelves
                      .map(
                        (shelf) => DropdownMenuItem(
                          value: shelf.id,
                          child: Text(shelf.name),
                        ),
                      )
                      .toList(),
                  onChanged: (shelfId) {
                    if (shelfId != null) {
                      setState(() => _shelfId = shelfId);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Buku'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit(
      Book(
        id: 'book-${DateTime.now().microsecondsSinceEpoch}',
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        category: _categoryController.text.trim(),
        shelfId: _shelfId,
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }
}

class _AddShelfSheet extends StatefulWidget {
  const _AddShelfSheet({required this.onSubmit});

  final ValueChanged<Shelf> onSubmit;

  @override
  State<_AddShelfSheet> createState() => _AddShelfSheetState();
}

class _AddShelfSheetState extends State<_AddShelfSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
                  labelText: 'Nama rak',
                  border: OutlineInputBorder(),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: _required,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan Rak'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit(
      Shelf(
        id: 'shelf-${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }
}
