// Util: RupiahFormatter
// Semua uang disimpan sebagai integer rupiah (bukan double/decimal).
// Format tampilan: Rp20.000 — Rp30.000 — dst.

import 'package:intl/intl.dart';

/// Format integer rupiah menjadi string "Rp20.000"
String formatRupiah(int nominal) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return formatter.format(nominal);
}

/// Parse string rupiah menjadi integer.
/// Menerima: "20000", "20.000", "Rp20.000", "Rp 20.000"
/// Mengembalikan null jika tidak valid.
int? parseRupiah(String input) {
  final bersih = input
      .replaceAll('Rp', '')
      .replaceAll('.', '')
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .trim();
  return int.tryParse(bersih);
}

/// Validasi nominal iuran sesuai batas yang dikonfigurasi.
/// Mengembalikan pesan error bahasa Indonesia, atau null jika valid.
String? validasiIuran(int nominal, {required int min, required int max}) {
  if (nominal < min) {
    return 'Nominal iuran minimal ${formatRupiah(min)}';
  }
  if (nominal > max) {
    return 'Nominal iuran maksimal ${formatRupiah(max)}';
  }
  return null;
}

/// Validasi nominal umum (tidak boleh nol atau negatif)
String? validasiNominalPositif(int? nominal) {
  if (nominal == null || nominal <= 0) {
    return 'Nominal harus lebih dari Rp0';
  }
  return null;
}
