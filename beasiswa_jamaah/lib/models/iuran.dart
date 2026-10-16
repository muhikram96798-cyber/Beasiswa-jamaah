// Model: Iuran
// Satu baris = satu pembayaran iuran satu bulan oleh satu donatur.
// Saat dicatat, otomatis membuat TransaksiKas MASUK kategori IURAN.

class Iuran {
  final int? id;
  final int donaturId;
  final int bulan; // 1–12
  final int tahunAjaran; // contoh: 2025
  final int nominal; // Rupiah aktual yang dibayar
  final String tanggalBayar; // ISO-8601 YYYY-MM-DD
  final int? transaksiKasId; // FK ke transaksi_kas.id, diisi otomatis

  const Iuran({
    this.id,
    required this.donaturId,
    required this.bulan,
    required this.tahunAjaran,
    required this.nominal,
    required this.tanggalBayar,
    this.transaksiKasId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'donatur_id': donaturId,
      'bulan': bulan,
      'tahun_ajaran': tahunAjaran,
      'nominal': nominal,
      'tanggal_bayar': tanggalBayar,
      'transaksi_kas_id': transaksiKasId,
    };
  }

  factory Iuran.fromMap(Map<String, dynamic> map) {
    return Iuran(
      id: map['id'] as int?,
      donaturId: map['donatur_id'] as int,
      bulan: map['bulan'] as int,
      tahunAjaran: map['tahun_ajaran'] as int,
      nominal: map['nominal'] as int,
      tanggalBayar: map['tanggal_bayar'] as String,
      transaksiKasId: map['transaksi_kas_id'] as int?,
    );
  }

  Iuran copyWith({int? id, int? transaksiKasId}) {
    return Iuran(
      id: id ?? this.id,
      donaturId: donaturId,
      bulan: bulan,
      tahunAjaran: tahunAjaran,
      nominal: nominal,
      tanggalBayar: tanggalBayar,
      transaksiKasId: transaksiKasId ?? this.transaksiKasId,
    );
  }
}
