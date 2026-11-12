# 🎓 Beasiswa Jamaah Tetap

<p align="center">
  <img src="assets/images/logo.png" alt="Logo Beasiswa Jamaah" width="140" style="border-radius: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.15);"/>
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

- **⚡ 100% Offline-First**: Database lokal SQLite (`sqflite`), privasi tinggi, tanpa kuota internet, tanpa biaya sewa server cloud.
- **🛡️ Auto Dana Cadangan 10%**: Otomatis menyisihkan 10% setiap iuran masuk ke pos dana darurat yang aman dan terpisah dari saldo siap pakai.
- **👥 Manajemen Donatur & Matriks 12 Bulan**: Pantau keaktifan donatur sepanjang tahun, buat pengingat WhatsApp santun berformat QRIS masjid & nomor rekening donasi.
- **🔒 Privasi Anak & Kode Samaran**: Identitas asli disamarkan dengan kode internal (`A-01`) dan inisial (`A.F. - SD`). Data sensitif diproteksi PIN 6-digit Salted SHA-256.
- **📊 Algoritma Scoring Seleksi**: Penilaian otomatis berdasarkan status yatim, kondisi ekonomi, saudara kandung, dan PIP.
- **🛍️ SOP Penyaluran Mitra Toko**: Belanja perlengkapan sekolah langsung dibayarkan ke vendor/toko rekanan; uang saku diserahkan melalui orang tua/wali murid.
- **📄 Laporan PDF Resmi Sekali Tap**: Dokumen pertanggungjawaban standar A4 lengkap dengan barcode, matriks donatur, rincian nota toko, dan pengesahan DKM.
- **💾 Ekspor & Impor Database (.db)**: Pencadangan aman berkala ke file fisik untuk kemudahan migrasi HP pengurus.

---

## 🚀 Perintah Cepat

```bash
# Dependensi
flutter pub get

# Pemeriksaan Kualitas
flutter analyze
flutter test

# Kompilasi APK
flutter build apk --release
```

---

<p align="center">
  Dibuat dengan segenap kepedulian untuk kemaslahatan umat dan pendidikan anak bangsa 🇮🇩
</p>
