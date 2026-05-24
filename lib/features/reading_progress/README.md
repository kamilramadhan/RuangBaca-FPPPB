# Reading Progress Tracker

Fitur untuk memantau progress membaca: halaman saat ini, persentase selesai, sesi baca, streak harian, target bulanan.

## Owner
Developer B.

## Struktur
- `data/models/` — entitas ReadingSession, ProgressEntry.
- `data/repositories/` — sumber data.
- `presentation/pages/` — halaman/layar.
- `presentation/widgets/` — widget khusus fitur ini (chart, progress bar, dll).
- `reading_progress.dart` — barrel file.

## Aturan
- Jangan import file dari fitur lain. Kalau butuh shared, taruh di `lib/core/`.
- Kalau butuh data buku dari Smart Bookshelf, koordinasi via shared model di `lib/core/` atau lewat ID saja.
