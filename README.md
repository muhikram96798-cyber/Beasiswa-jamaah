# 🎓 Beasiswa Jamaah Tetap

<p align="center">
  <img src="beasiswa_jamaah/assets/images/logo.png" alt="Logo Beasiswa Jamaah" width="140" style="border-radius: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.15);"/>
</p>

<p align="center">
  <b>Sistem Pengelolaan Beasiswa Pendidikan Anak Yatim & Dhuafa Berbasis Jamaah Masjid</b><br>
  <i>Amanah • Transparan • Memberdayakan Jamaah • 100% Offline-First</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter 3.x"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart 3.x"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20API%2021%2B-3DDC84?logo=android&logoColor=white" alt="Android"/>
  <img src="https://img.shields.io/badge/Database-SQLite%20(sqflite)-003B57?logo=sqlite&logoColor=white" alt="SQLite"/>
  <img src="https://img.shields.io/badge/Design-Material%203%20Emerald-2E7D32" alt="Material 3"/>
  <img src="https://img.shields.io/badge/Tests-73%2F73%20Passed-brightgreen" alt="Tests 100% Passed"/>
  <img src="https://img.shields.io/badge/Analysis-0%20Issues-brightgreen" alt="0 Issues"/>
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"/>
</p>

---

## 📌 Sekilas Program

**Aplikasi Beasiswa Jamaah Tetap** adalah aplikasi mobile Android *offline-first* yang dirancang khusus untuk memfasilitasi pengurus Dewan Kemakmuran Masjid (DKM), panitia beasiswa, bendahara, dan remaja masjid (RISMA) dalam mengelola program beasiswa pendidikan bagi anak yatim, piatu, dan dhuafa di lingkungan sekitar tempat ibadah.

Aplikasi ini mengusung prinsip **iuran gotong-royong ringan (Rp20.000 – Rp30.000/bulan per donatur)** yang dikumpulkan secara istiqomah oleh puluhan hingga ratusan jamaah tetap, sehingga mampu membiayai kebutuhan seragam, buku, sepatu, dan uang saku anak-anak berprestasi dan pra-sejahtera tanpa membebani kas utama masjid.

---

## ✨ Fitur & Keunggulan Utama

### 1. ⚡ 100% Offline-First (Tanpa Kuota Internet)
- Seluruh data transaksi, donatur, dan anak tersimpan langsung di penyimpanan fisik perangkat menggunakan database **SQLite lokal** (`sqflite`).
- Aplikasi berjalan instan, super cepat, tanpa login server, tanpa kuota internet, dan tanpa biaya sewa cloud bulanan.

### 2. 🛡️ Pemisahan Otomatis Pos Dana Cadangan 10%
- Setiap penerimaan iuran atau infak beasiswa **secara otomatis memisahkan 10%** ke dalam pos dana cadangan wajib.
- Saldo siap pakai untuk penyaluran beasiswa terpisah tegas dari dana cadangan darurat, menjamin ketahanan keuangan jangka panjang.

### 3. 👥 Manajemen Donatur & Matriks Iuran 12 Bulan
- Pencatatan donatur tetap dengan komitmen bulanan terjangkau.
- **Matriks Iuran 12 Bulan**: visualisasi kisi transparan bulan Januari – Desember (status lunas/belum lunas).
- Integrasi **WhatsApp Pengingat Otomatis**: pembuatan pesan tagihan santun via WhatsApp yang memuat nomor rekening resmi donasi & barcode QRIS masjid.
- Fitur **Pembatalan Iuran**: opsi pembatalan fleksibel yang otomatis mengembalikan saldo kas dan mencatat mutasi pengembalian secara rapi.

### 4. 🔒 Perlindungan Martabat & Privasi Anak (Kerahasiaan Tinggi)
- **Privasi Terjaga**: Nama lengkap anak tidak pernah ditampilkan di layar umum maupun laporan pertanggungjawaban publik; sistem menggunakan kode unik (`A-01`) dan inisial samaran (`A.F. - SMA Kelas 12`).
- **Proteksi PIN Salted SHA-256**: Data sensitif (nama lengkap, NIK, nama wali, alamat rumah) dikunci dengan PIN keamanan 6-digit.
- **Scoring Seleksi Objektif**: Algoritma cerdas yang menghitung skor kelayakan beasiswa berdasarkan status yatim/piatu, kondisi ekonomi keluarga, jumlah tanggungan saudara, dan status Program Indonesia Pintar (PIP).

### 5. 🛍️ SOP Penyaluran Anti-Penyalahgunaan
- Bantuan belanja seragam, sepatu, buku, dan tas sekolah **wajib disalurkan ke toko/vendor rekanan** (bukan tunai ke anak).
- Bantuan uang saku bulanan diserahkan khusus melalui **wali murid/orang tua pendamping**.
- Fitur **Pembatalan Penyaluran**: dana belanja yang batal otomatis kembali ke saldo kas siap pakai tanpa merusak riwayat transaksi.

### 6. 📄 Laporan Pertanggungjawaban PDF Resmi 1-Klik
- Otomatis meng-generate dokumen PDF laporan semesteran (Sem 1, Sem 2, atau 1 Tahun Penuh) berstandar akuntansi DKM.
- Memuat rekapitulasi kas masuk/keluar, saldo cadangan 10%, kepatuhan SOP, matriks 12 bulan donatur, rincian nota toko, dan lembar pengesahan tanda tangan ketua DKM & bendahara.
- Dapat langsung dicetak ke printer fisik atau dibagikan ke grup WhatsApp Jamaah.

### 7. 💾 Cadangkan & Pulihkan Database (.db)
- Pengurus dapat mengekspor salinan database SQLite (`.db`) kapan saja ke Google Drive, memori HP, atau WhatsApp.
- Jika pengurus berganti HP, cukup gunakan menu **Pulihkan Data** untuk merestorasi seluruh data dalam hitungan detik.

---

## 📱 Struktur Navigasi Aplikasi (5 Tab Utama)

```
Beasiswa Jamaah Tetap
├── 🏠 Beranda      -> Saldo kas siap pakai, pos cadangan 10%, KPI indikator proposal, aksi cepat
├── 👥 Donatur      -> Daftar donatur, status lunas iuran, matriks 12 bulan, kirim tagihan WA
├── 💳 Kas          -> Arus kas masuk/keluar, saldo terpisah, mutasi transaksi detail
├── 🎓 Anak         -> Data penerima beasiswa, scoring seleksi, progres dana pendidikan
└── 📄 Laporan      -> Generator PDF resmi semesteran, kepatuhan SOP, cetak & share WA
```

---

## 🛠️ Arsitektur & Teknologi

| Komponen | Teknologi |
|---|---|
| **Framework** | Flutter 3.x (SDK Dart 3.x) |
| **Pola Arsitektur** | Provider Pattern (`MultiProvider`) dengan pemisahan Service & Model yang modular |
| **Database** | SQLite via `sqflite` (FOREIGN KEY constraint ON, transaction ACID-compliant) |
| **Keamanan** | SHA-256 + Unique Salt hashing untuk proteksi PIN pengurus |
| **Desain UI** | Material 3 Green Emerald Theme (`#2E7D32`), tipografi kontras tinggi ramah lansia |
| **PDF & Dokumen** | `pdf` & `printing` (Format A4 resmi dengan barcode & tabel rekap) |
| **Sharing & I/O** | `share_plus` & `file_picker` |
| **Format Lokalisasi** | `intl` (Rupiah Indonesia `id_ID` & Kalender Nasional) |

---

## 📂 Struktur Direktori Proyek

```
beasiswa-jamaah-app/
├── beasiswa_jamaah/                # Source code Flutter
│   ├── android/                    # Konfigurasi native Android, icon launcher & manifest
│   ├── assets/images/              # Aset visual & logo resmi aplikasi
│   ├── lib/
│   │   ├── models/                 # Model data: Anak, Donatur, Iuran, Kas, Pengaturan, Penyaluran
│   │   ├── providers/              # State management: ChangeNotifier untuk setiap modul
│   │   ├── screens/                # Tampilan UI 5 tab (Beranda, Donatur, Kas, Anak, Laporan, Pengaturan)
│   │   ├── services/               # Layanan logika database SQLite, enkripsi, PDF & backup
│   │   ├── utils/                  # Helper: format Rupiah, generator inisial, scoring seleksi, WA helper
│   │   ├── widgets/                # Reusable UI widgets: dialog konfirmasi, dialog PIN, empty state
│   │   ├── app.dart                # Shell navigasi & konfigurasi tema Material 3
│   │   └── main.dart               # Entry point aplikasi
│   ├── test/                       # 73 unit & widget automated test suite
│   └── pubspec.yaml                # Dependensi & aset konfigurasi Flutter
├── .gitignore                      # Proteksi file binary/cache/APK
└── README.md                       # Dokumentasi utama proyek
```

---

## 🚀 Panduan Membangun & Menjalankan (Development)

### Prasyarat
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versi 3.13+)
- [Android Studio / Android SDK](https://developer.android.com/studio) (API 21 - 36)
- Java Development Kit (JDK 17+)

### Langkah Instalasi
```bash
# 1. Clone repositori ini
git clone https://github.com/muhikram96798-cyber/Beasiswa-jamaah.git
cd Beasiswa-jamaah/beasiswa_jamaah

# 2. Ambil seluruh dependencies
flutter pub get

# 3. Jalankan analisis kualitas kode (0 warning / 0 issue)
flutter analyze

# 4. Jalankan seluruh automated test suite (73 tests)
flutter test

# 5. Jalankan aplikasi di HP Android (Hubungkan HP via USB / Debugging)
flutter run
```

### Membuat File APK
```bash
# Build APK Debug (untuk pengujian)
flutter build apk --debug

# Build APK Release resmi (teroptimasi & terkompresi)
flutter build apk --release
```
*File APK yang dihasilkan akan berada di: `beasiswa_jamaah/build/app/outputs/flutter-apk/app-release.apk`*

---

## 🧪 Jaminan Kualitas & Pengujian (Quality Assurance)

Proyek ini telah dilengkapi **73 Automated Unit & Widget Tests** yang mencakup:
- ✅ **Integritas Database**: Uji Foreign Key SQLite saat donatur atau anak dihapus.
- ✅ **Logika Kas & Iuran**: Pemisahan 10% dana cadangan otomatis dan pencegahan duplikasi pencatatan.
- ✅ **Logika Penyaluran**: Transaksi belanja perlengkapan sekolah ke toko dan penyerahan uang saku ke wali.
- ✅ **Pembatalan Transaksi**: Pengembalian saldo kas otomatis pada fitur batalkan iuran / bantuan.
- ✅ **Scoring Seleksi**: Perhitungan bobot objektif kebutuhan dana anak berdasar jenjang dan PIP.
- ✅ **Format & UI**: Pengujian bebas dari *RenderFlex Overflow* pada layar sempit Android (360x640 dp).
- ✅ **Generator PDF**: Pembuatan laporan keuangan dan dokumen pertanggungjawaban lengkap.

---

## 🤝 Berkontribusi & Hak Penggunaan

Aplikasi ini dikembangkan untuk kemaslahatan umat, pemberdayaan ekonomi jamaah, dan pemenuhan hak pendidikan bagi anak yatim dan dhuafa di lingkungan masjid.

Setiap bentuk kontribusi, *pull request*, maupun saran fitur baru untuk kemajuan program kemaslahatan jamaah sangat disambut dengan tangan terbuka.

---

<p align="center">
  Dibuat dengan segenap kepedulian untuk kemaslahatan umat dan pendidikan anak bangsa 🇮🇩<br>
  <b>Dewan Kemakmuran Masjid & Komunitas Pemuda Jamaah</b>
</p>
