# Aplikasi Beasiswa Jamaah Tetap

Aplikasi Android *offline-first* untuk pengelolaan program beasiswa pendidikan anak yatim, piatu, dan dhuafa berbasis jamaah tempat ibadah (masjid/musholla).

Aplikasi ini dirancang khusus untuk memfasilitasi pengurus DKM, bendahara, dan koordinator pendidikan yang awam teknologi agar dapat mengelola iuran jamaah, menyeleksi anak penerima, dan menerbitkan laporan pertanggungjawaban secara amanah, transparan, dan terpercaya.

---

## 🌟 Prinsip & Keunggulan Utama

1. **100% Offline-First (Tanpa Perlu Kuota/Internet)**:
   - Menggunakan database **SQLite lokal**. Seluruh data tersimpan aman di perangkat fisik pengurus tanpa ketergantungan server atau biaya langganan cloud.
2. **Iuran Jamaah Ringan & Terjangkau**:
   - Iuran donatur tetap dipatok **Rp20.000 – Rp30.000 per bulan** agar jamaah dapat berdonasi secara istiqomah tanpa merasa terbebani.
3. **Pemisahan Otomatis Pos Dana Cadangan 10%**:
   - Setiap pemasukan iuran otomatis menyisihkan 10% ke dalam pos cadangan wajib untuk kebutuhan darurat (hanya bisa dicairkan atas konfirmasi tertulis pengurus).
4. **SOP Anti-Penyalahgunaan Penyaluran**:
   - Bantuan perlengkapan sekolah (seragam, sepatu, buku, tas) **HANYA dibayarkan ke vendor/penjahit/toko rekanan** (bukan tunai ke anak).
   - Bantuan uang saku bulanan **HANYA diserahkan melalui wali murid/orang tua pendamping**.
5. **Perlindungan Privasi & Martabat Anak (Kerahasiaan Tinggi)**:
   - Nama asli anak tidak pernah muncul pada daftar umum atau laporan publik (menggunakan kode internal `A-01` dan inisial `A.F. - SD Kelas 3`).
   - Rincian identitas asli diproteksi oleh **PIN Keamanan 6-digit (Salted SHA-256)**.
6. **Laporan Pertanggungjawaban PDF Resmi**:
   - Mencakup rekap kas, transparansi matriks donatur 12 bulan, evaluasi 4 indikator proposal, rincian penyaluran, dan lembar pengesahan tanda tangan DKM.
   - Dapat dicetak langsung ke printer fisik atau dibagikan ke WhatsApp Jamaah dalam 1 ketukan.
7. **Pencadangan Database Berkala**:
   - Fitur ekspor/backup file `.db` dan pemulihan/restore data sewaktu-waktu jika pengurus berganti HP.
8. **Persiapan Pembayaran QRIS & Transfer Bank**:
   - Integrasi pesan pengingat WhatsApp otomatis yang memuat nomor rekening donasi dan instruksi scan QRIS masjid.

---

## 📱 Arsitektur & Teknologi

- **Framework**: Flutter 3.x (Android Target)
- **Desain UI**: Material 3 Green Theme (`#2E7D32`), tipografi besar & kontras ramah lansia
- **State Management**: `provider` (MultiProvider)
- **Database**: `sqflite` (SQLite v2 dengan FOREIGN KEY ON)
- **Keamanan**: `crypto` (Salted SHA-256 untuk PIN pengurus)
- **Dokumen PDF & Cetak**: `pdf` & `printing`
- **File & Berbagi**: `share_plus` & `file_picker`
- **Format Angka & Waktu**: `intl` (Rupiah Indonesia & Kalender Masehi)

---

## 🗄️ Skema Database SQLite (`beasiswa_jamaah.db`)

| Tabel | Deskripsi |
|---|---|
| `donatur` | Data keluarga donatur tetap, komitmen bulanan (Rp20k–30k), dan status keaktifan |
| `iuran` | Riwayat pembayaran iuran 12 bulan (terhubung otomatis ke transaksi kas) |
| `transaksi_kas` | Rekapitulasi mutasi kas masuk/keluar, pos cadangan 10%, dan saldo siap pakai |
| `anak` | Data penerima beasiswa (kode unik, inisial samaran, jenjang SD/SMP/SMA, skor seleksi, status PIP) |
| `penyaluran` | Riwayat belanja perlengkapan ke toko dan penyerahan uang saku ke wali murid |
| `pengaturan` | Konfigurasi biaya pendidikan, PIP, bobot seleksi, data rekening/QRIS, dan hash PIN pengurus |

---

## 🚀 Menjalankan Aplikasi & Pengujian

### Prasyarat
- Flutter SDK (v3.13.5+)
- Android SDK & Java JDK 17+

### Perintah Utama
```bash
# Mengambil dependencies
flutter pub get

# Memeriksa kebersihan kode (0 issues)
flutter analyze

# Menjalankan 55 unit test program
flutter test

# Membangun APK Debug
flutter build apk --debug

# Membangun APK Rilis untuk HP Android
flutter build apk --release
```

---

## 👥 Hak Cipta & Penggunaan

Aplikasi ini dikembangkan untuk kemaslahatan umat dan program pemberdayaan pendidikan anak yatim dan dhuafa jamaah tempat ibadah.
