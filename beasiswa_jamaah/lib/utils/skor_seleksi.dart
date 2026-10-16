// Util: SkorSeleksi
// Menghitung skor kelayakan anak penerima beasiswa (0–100).
// Semua bobot bisa diubah di pengaturan; nilai hardcode hanya sebagai default.
// Skor ini hanya alat bantu pengurus, bukan penentu mutlak.

import '../models/anak.dart';

/// Menghitung skor seleksi anak berdasarkan bobot yang dikonfigurasi.
///
/// [bobotEkonomi] : bobot kondisi ekonomi (default 40)
/// [bobotYatim]   : bobot status yatim/piatu (default 30)
/// [bobotSaudara] : bobot jumlah saudara (default 15)
/// [bobotKip]     : bobot status KIP/PIP (default 15)
///
/// Total keempat bobot sebaiknya = 100.
int hitungSkor({
  required KondisiEkonomi kondisiEkonomi,
  required StatusYatim statusYatim,
  required int jumlahSaudara,
  required StatusPip statusPip,
  required int bobotEkonomi,
  required int bobotYatim,
  required int bobotSaudara,
  required int bobotKip,
}) {
  final nilaiEkonomi = _nilaiEkonomi(kondisiEkonomi);
  final nilaiYatim = _nilaiYatim(statusYatim);
  final nilaiSaudara = _nilaiSaudara(jumlahSaudara);
  final nilaiKip = _nilaiKip(statusPip);

  // Skor masing-masing komponen sudah dalam rentang 0–1 (proporsi penuh)
  // lalu dikalikan bobot
  final skor = (nilaiEkonomi * bobotEkonomi) +
      (nilaiYatim * bobotYatim) +
      (nilaiSaudara * bobotSaudara) +
      (nilaiKip * bobotKip);

  return skor.round().clamp(0, 100);
}

/// Kondisi ekonomi: proporsi 0.0–1.0
double _nilaiEkonomi(KondisiEkonomi kondisi) {
  switch (kondisi) {
    case KondisiEkonomi.sangatKurang:
      return 1.0; // skor penuh
    case KondisiEkonomi.kurang:
      return 0.625; // ≈ 25/40
    case KondisiEkonomi.cukup:
      return 0.25; // ≈ 10/40
  }
}

/// Status yatim/piatu: proporsi 0.0–1.0
double _nilaiYatim(StatusYatim status) {
  switch (status) {
    case StatusYatim.yatimPiatu:
      return 1.0; // skor penuh
    case StatusYatim.yatim:
    case StatusYatim.piatu:
      return 0.667; // ≈ 20/30
    case StatusYatim.lengkap:
      return 0.0;
  }
}

/// Jumlah saudara: proporsi 0.0–1.0
double _nilaiSaudara(int jumlah) {
  if (jumlah >= 4) return 1.0; // skor penuh
  if (jumlah >= 2) return 0.667; // ≈ 10/15
  if (jumlah == 1) return 0.333; // ≈ 5/15
  return 0.0; // anak tunggal
}

/// Status KIP/PIP: proporsi 0.0–1.0
/// Tidak punya KIP = lebih butuh bantuan = skor lebih tinggi
double _nilaiKip(StatusPip status) {
  switch (status) {
    case StatusPip.belum:
      return 1.0; // skor penuh — belum punya KIP
    case StatusPip.sedangDiurus:
      return 0.533; // ≈ 8/15 — dalam proses
    case StatusPip.sudahMenerima:
      return 0.0; // sudah dapat bantuan pemerintah
  }
}

/// Deskripsi singkat komponen skor (untuk ditampilkan di UI)
String deskripsikomponen({
  required int bobotEkonomi,
  required int bobotYatim,
  required int bobotSaudara,
  required int bobotKip,
}) {
  return 'Kondisi ekonomi ($bobotEkonomi poin) + '
      'Status yatim/piatu ($bobotYatim poin) + '
      'Jumlah saudara ($bobotSaudara poin) + '
      'Status KIP/PIP ($bobotKip poin)';
}
