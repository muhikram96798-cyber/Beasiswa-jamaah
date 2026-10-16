// Util: InisialHelper
// Menghasilkan nama samaran anak untuk ditampilkan di daftar dan laporan.
// Format: "A.F. - SD Kelas 3" (inisial nama + jenjang + kelas)
// Kode unik: "A-01", "A-02", dst.

import '../models/anak.dart';

/// Buat nama samaran dari nama lengkap dan data jenjang/kelas.
/// Contoh: namaLengkap="Ahmad Fauzi", jenjang=SD, kelas=3
///   → "A.F. - SD Kelas 3"
String buatNamaSamaran({
  required String namaLengkap,
  required Jenjang jenjang,
  required int kelas,
}) {
  final inisial = _buatInisial(namaLengkap);
  return '$inisial - ${jenjang.label} Kelas $kelas';
}

/// Buat kode anak berikutnya dari daftar kode yang sudah ada.
/// Format: "A-01", "A-02", ..., "A-10", "A-11", dst.
String buatKodeAnak(List<String> kodeYangAda) {
  int nomor = 1;
  while (true) {
    final kode = 'A-${nomor.toString().padLeft(2, '0')}';
    if (!kodeYangAda.contains(kode)) return kode;
    nomor++;
  }
}

/// Buat inisial dari nama lengkap.
/// "Ahmad Fauzi Ramadan" → "A.F.R."
/// "Siti" → "S."
String _buatInisial(String namaLengkap) {
  final kataKata = namaLengkap
      .trim()
      .split(RegExp(r'\s+'))
      .where((k) => k.isNotEmpty)
      .toList();

  if (kataKata.isEmpty) return '?';

  return kataKata
      .map((k) => '${k[0].toUpperCase()}.')
      .join('');
}

/// Samarkan nama untuk konteks laporan (tidak perlu kode unik).
/// Identik dengan buatNamaSamaran — pisahkan agar mudah ditest.
String samarkanNama(String namaLengkap, Jenjang jenjang, int kelas) {
  return buatNamaSamaran(
    namaLengkap: namaLengkap,
    jenjang: jenjang,
    kelas: kelas,
  );
}
