/// Barrel file untuk fitur Smart Bookshelf.
/// Import file ini dari luar fitur, jangan import file internal langsung.
library;

export 'data/models/book.dart';
export 'data/repositories/bookshelf_repository.dart'
    show BookshelfRepository, BookshelfRepositoryFactory;
export 'presentation/pages/bookshelf_page.dart';
