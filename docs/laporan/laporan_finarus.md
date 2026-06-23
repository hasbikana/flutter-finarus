# LAPORAN UJIAN AKHIR SEMESTER
## Mobile Programming Lanjut

---

**Nama Aplikasi**: Finarus

**Tujuan Aplikasi**: Aplikasi FINARUS keuangan pribadi berbasis Flutter yang membantu pengguna mencatat transaksi, menyusun anggaran, mengelola dompet, menetapkan target tabungan, serta melakukan deteksi otomatis transaksi dari struk belanja (OCR) dan notifikasi aplikasi pembayaran.

**Fitur Utama**:
- Autentikasi pengguna (email & password serta Google OAuth)
- Dashboard interaktif dengan ringkasan saldo, pemasukan, dan pengeluaran
- Manajemen transaksi (Create, Read, Update, Delete) dengan pencarian dan filter
- Manajemen dompet multi-akun (bank, e-wallet, kartu kredit, tunai)
- Anggaran bulanan per kategori dengan peringatan batas anggaran
- Manajemen kategori kustom dengan emoji dan color picker
- Target tabungan (saving goals) dengan deadline tracking
- Laporan keuangan bulanan dan tahunan dengan visualisasi chart (pie & bar)
- Scan struk otomatis berbasis Google ML Kit Text Recognition
- Auto-capture notifikasi transaksi dari aplikasi pembayaran
- Notifikasi peringatan anggaran, saldo minus, dan transaksi masuk
- Pengaturan preferensi pengguna dan integrasi akun Google

**Tautan GitHub**: [LINK_GITHUB]

---

## 1. Penjelasan Singkat

Perkembangan teknologi informasi telah mengubah secara fundamental cara individu dalam mengelola keuangan pribadinya. Pada era sebelumnya, pencatatan transaksi keuangan umumnya dilakukan secara manual melalui buku catatan atau spreadsheet yang memiliki keterbatasan, seperti risiko kehilangan data, sulitnya melakukan analisis pola pengeluaran, serta tidak tersedianya notifikasi real-time ketika pengguna mendekati batas anggaran. Di sisi lain, ketersebaran aktivitas transaksi pada berbagai platform pembayaran digital (mobile banking, e-wallet, dan QRIS) menuntut sebuah solusi terintegrasi yang mampu menghimpun seluruh catatan transaksi dalam satu genggaman. Kebutuhan inilah yang menjadi latar belakang pengembangan aplikasi **Finarus**, yaitu aplikasi mobile berbasis Flutter yang dirancang untuk membantu pengguna mengelola keuangan pribadi secara menyeluruh, mulai dari pencatatan transaksi, penyusunan anggaran, hingga penetapan target tabungan.

Finarus dikembangkan dengan mengadopsi pola arsitektur berlapis yang terdiri atas empat lapisan utama, yaitu *Model* untuk representasi data, *Provider* sebagai state management berbasis package `provider`, *Service* untuk abstraksi komunikasi HTTP menuju REST API backend Laravel, serta *Screen* sebagai lapisan presentasi antarmuka pengguna. Aplikasi ini menyediakan fitur unggulan berupa *dashboard* interaktif yang menampilkan total saldo, ringkasan pemasukan dan pengeluaran, serta daftar transaksi terbaru. Fitur diferensiasi utama Finarus terletak pada kemampuan *auto-detection* transaksi, yaitu pemindaian struk belanja secara otomatis menggunakan kamera dengan teknologi *Google ML Kit Text Recognition*, serta pemrosesan notifikasi masuk dari aplikasi pembayaran seperti DANA, OVO, dan GoPay yang secara otomatis diekstraksi menjadi kandidat transaksi. Autentikasi pengguna didukung oleh dua mekanisme, yaitu email dan kata sandi (disimpan secara aman menggunakan `flutter_secure_storage`) serta *Single Sign-On* melalui Google OAuth. Seluruh data transaksi divisualisasikan dalam bentuk diagram lingkaran (*pie chart*) untuk komposisi pengeluaran per kategori dan diagram batang (*bar chart*) untuk tren tahunan, sehingga pengguna dapat dengan mudah menganalisis pola keuangan mereka.

---

## 2. Screenshot Tampilan Antarmuka Aplikasi

> **Petunjuk**: Tempatkan screenshot aplikasi pada bagian di bawah ini. Disarankan untuk menyertakan tangkapan layar dari setiap halaman utama aplikasi agar pembaca laporan dapat memahami antarmuka dan alur penggunaan aplikasi secara visual.

### 2.1 Halaman Autentikasi
- Halaman Login
- Halaman Register

### 2.2 Halaman Utama
- Halaman Dashboard (Beranda) — menampilkan total saldo, ringkasan pemasukan/pengeluaran, menu cepat, transaksi terbaru, dan progress anggaran
- Halaman Transaksi — daftar transaksi dengan fitur pencarian dan filter

### 2.3 Halaman Manajemen
- Halaman Dompet (Accounts) — daftar dompet yang dikelompokkan berdasarkan tipe (Tunai, Bank, E-Wallet, Kartu Kredit)
- Halaman Anggaran (Budgets) — daftar anggaran bulanan per kategori
- Halaman Kategori — grid kategori dengan emoji dan warna
- Halaman Tabungan (Savings) — daftar target tabungan dengan progress bar

### 2.4 Haporan dan Notifikasi
- Halaman Laporan — chart pie pengeluaran per kategori dan chart bar tren tahunan
- Halaman Notifikasi — daftar transaksi yang menunggu konfirmasi dan riwayat notifikasi

### 2.5 Fitur Tambahan
- Halaman Scan OCR — pemindaian struk dari kamera atau galeri
- Halaman Pengaturan (Settings) — preferensi notifikasi dan integrasi Google
- Halaman Profil — informasi pengguna, ubah kata sandi, dan keluar

---

## 3. Kode Program

Seluruh kode sumber aplikasi **Finarus** tersedia pada repository GitHub berikut:

> **Tautan Repository**: `[LINK_GITHUB]`

### Struktur Direktori Utama

```
finarus_flutter/
├── lib/
│   ├── main.dart                  # Entry point & MultiProvider setup
│   ├── config/                    # Konfigurasi (API, colors)
│   │   ├── api_config.dart        # Base URL & Google Client ID
│   │   └── colors.dart            # Palet warna & gradient
│   ├── models/                    # Model data (10 file)
│   │   ├── user.dart
│   │   ├── account.dart
│   │   ├── transaction.dart
│   │   ├── budget.dart
│   │   ├── category.dart
│   │   ├── saving_goal.dart
│   │   └── ...
│   ├── providers/                 # State management (12 file)
│   │   ├── auth_provider.dart
│   │   ├── dashboard_provider.dart
│   │   ├── transaction_provider.dart
│   │   ├── ocr_provider.dart
│   │   └── ...
│   ├── services/                  # HTTP service layer (12 file)
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── transaction_service.dart
│   │   └── ...
│   ├── screens/                   # Halaman UI (14 file)
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── transactions_screen.dart
│   │   ├── reports_screen.dart
│   │   ├── profile_screen.dart
│   │   └── ...
│   ├── widgets/                   # Reusable widgets
│   ├── parsers/                   # OCR & notification parser
│   ├── utils/                     # Format utilities
│   └── assets/                    # Logo & gambar
├── docs/                          # Dokumentasi
├── android/                       # Konfigurasi Android
├── ios/                           # Konfigurasi iOS
└── pubspec.yaml                   # Dependencies
```

### Dependensi Utama (pubspec.yaml)

| Package | Versi | Fungsi |
|---|---|---|
| `provider` | ^6.1.0 | State management |
| `http` | ^1.2.0 | HTTP client untuk REST API |
| `flutter_secure_storage` | ^9.2.0 | Penyimpanan token aman |
| `google_sign_in` | ^6.2.0 | Autentikasi Google OAuth |
| `fl_chart` | ^0.68.0 | Visualisasi chart (pie & bar) |
| `image_picker` | ^1.1.0 | Pilih gambar dari kamera/galeri |
| `google_mlkit_text_recognition` | ^0.14.0 | OCR text recognition |
| `flutter_local_notifications` | ^17.0.0 | Notifikasi lokal |
| `intl` | ^0.19.0 | Format tanggal & rupiah |
| `open_filex` | ^4.4.0 | Buka file export laporan |
| `shared_preferences` | ^2.3.0 | Preferensi lokal |
| `cupertino_icons` | ^1.0.8 | Ikon iOS style |

---

*Laporan ini disusun untuk memenuhi tugas Ujian Akhir Semester mata kuliah Mobile Programming Lanjut.*
