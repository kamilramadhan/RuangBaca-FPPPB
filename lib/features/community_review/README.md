# Community Review & Discussion

Fitur sosial: user bisa menulis review buku, kasih rating, diskusi/thread, balasan, like.

## Owner
Developer C.

## Struktur
- `data/models/` — entitas Review, Discussion, Reply.
- `data/repositories/` — sumber data (backend API).
- `presentation/pages/` — halaman/layar.
- `presentation/widgets/` — widget khusus (review card, thread item, dll).
- `community_review.dart` — barrel file.

## Aturan
- Jangan import file dari fitur lain. Kalau butuh shared, taruh di `lib/core/`.
- Untuk reference buku, cukup pakai `bookId` (jangan import model Book dari Smart Bookshelf).
