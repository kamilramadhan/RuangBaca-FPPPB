# Ruang Baca

Aplikasi Flutter untuk pembaca buku. Tiga fitur utama dikerjakan paralel oleh tiga developer:

| Fitur | Deskripsi | Owner |
|-------|-----------|-------|
| **Smart Bookshelf** | Mengelola koleksi buku user: tambah/hapus, kategorisasi, rak custom, status (owned / wishlist / lent). | Dev A |
| **Reading Progress Tracker** | Memantau progress membaca: halaman saat ini, persentase selesai, sesi baca, streak, target. | Dev B |
| **Community Review & Discussion** | Review & rating buku, thread diskusi, balasan, like. | Dev C |

## Struktur Proyek

```
lib/
├── main.dart                  # entry point
├── app.dart                   # MaterialApp root
├── core/                      # kode SHARED lintas fitur
│   ├── constants/             # konstanta global (string, dll)
│   ├── routes/app_routes.dart # registrasi semua route
│   ├── theme/                 # tema aplikasi
│   ├── utils/                 # helper/util shared
│   └── widgets/               # widget shared (mis. home_page.dart)
└── features/                  # kode MODULAR — satu folder satu fitur
    ├── smart_bookshelf/        # Dev A
    ├── reading_progress/       # Dev B
    └── community_review/       # Dev C
```

Setiap folder fitur konsisten memakai struktur:

```
<feature>/
├── data/
│   ├── models/                # entitas/model data
│   └── repositories/          # sumber data (local DB / remote API)
├── presentation/
│   ├── pages/                 # halaman/layar
│   └── widgets/               # widget khusus fitur ini
├── <feature>.dart             # barrel file — satu-satunya entry dari luar
└── README.md                  # detail & catatan fitur
```

## Aturan Kolaborasi

Karena tiga developer mengerjakan tiga fitur berbeda secara paralel, ikuti aturan
berikut untuk menghindari konflik dan menjaga modularitas.

### 1. Batas antar-fitur
- **Jangan import file dari fitur lain.** Folder `features/<x>` tidak boleh meng-import
  apa pun dari `features/<y>`.
- Butuh kode bersama (model, util, widget)? Naikkan ke `lib/core/` lalu import dari sana.
- Perlu mereferensikan data fitur lain? Cukup pakai ID (mis. `bookId`), jangan import
  model milik fitur tetangga.

### 2. Barrel file
- Akses fitur dari luar **hanya** lewat barrel file (`features/<x>/<x>.dart`).
- Setiap halaman/komponen yang dipakai di luar fitur harus di-`export` di barrel file.
- Internal fitur (model, repository, widget privat) tidak perlu di-export.

### 3. File rawan konflik (koordinasi sebelum edit)
- `lib/core/routes/app_routes.dart` — semua dev menambah route di sini.
- `lib/core/widgets/home_page.dart` — menu utama yang menaut ke tiap fitur.
- `pubspec.yaml` — penambahan dependency.

Beri tahu tim di chat sebelum mengubah file-file ini, dan commit perubahannya kecil & terpisah.

### 4. Alur menambah fitur/halaman baru
1. Buat halaman di `features/<x>/presentation/pages/`.
2. `export` halaman tersebut di `features/<x>/<x>.dart`.
3. Daftarkan konstanta + builder route di `lib/core/routes/app_routes.dart`.
4. (Opsional) Tambahkan tautan menu di `lib/core/widgets/home_page.dart`.

### 5. Branch & commit
- Satu branch per fitur: `feature/smart-bookshelf`, `feature/reading-progress`,
  `feature/community-review`.
- Commit kecil dan deskriptif; rebase/merge `main` secara berkala agar konflik kecil.
- Pastikan `flutter analyze` bersih sebelum push.

## Menjalankan

```bash
flutter pub get
flutter run
flutter analyze   # harus "No issues found!"
flutter test
```

Detail tiap fitur ada di `lib/features/<fitur>/README.md`.
