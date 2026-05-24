# Smart Bookshelf

Fitur untuk mengelola koleksi buku milik user (tambah, hapus, kategorisasi, rak custom, status "owned / wishlist / lent").

## Owner
Developer A.

## Struktur
- `data/models/` — entitas Book, Shelf, dll.
- `data/repositories/` — sumber data (local DB / remote API).
- `presentation/pages/` — halaman/layar.
- `presentation/widgets/` — widget khusus fitur ini.
- `smart_bookshelf.dart` — barrel file (satu-satunya yang boleh di-import dari luar fitur).

## Aturan
- Jangan import file dari fitur lain. Kalau butuh shared, taruh di `lib/core/`.
- Tambah route baru di `lib/core/routes/app_routes.dart` dan export halaman lewat barrel file.
