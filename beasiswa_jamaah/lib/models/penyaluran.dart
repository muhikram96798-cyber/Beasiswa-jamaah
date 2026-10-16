// Model: Penyaluran
// Mencatat setiap penyaluran bantuan ke anak penerima.
// Setiap penyaluran otomatis membuat TransaksiKas KELUAR.
// Perlengkapan HANYA boleh berupa barang (tidak ada opsi tunai ke anak).

/// Jenis penyaluran
enum JenisPenyaluran { seragam, sepatu, tas, buku, uangSaku, lain }

extension JenisPenyaluranX on JenisPenyaluran {
  String get value {
    switch (this) {
      case JenisPenyaluran.seragam:
        return 'SERAGAM';
      case JenisPenyaluran.sepatu:
        return 'SEPATU';
      case JenisPenyaluran.tas:
        return 'TAS';
      case JenisPenyaluran.buku:
        return 'BUKU';
      case JenisPenyaluran.uangSaku:
        return 'UANG_SAKU';
      case JenisPenyaluran.lain:
        return 'LAIN';
    }
  }

  String get label {
    switch (this) {
      case JenisPenyaluran.seragam:
        return 'Seragam';
      case JenisPenyaluran.sepatu:
        return 'Sepatu';
      case JenisPenyaluran.tas:
        return 'Tas';
      case JenisPenyaluran.buku:
        return 'Buku & Alat Tulis';
      case JenisPenyaluran.uangSaku:
        return 'Uang Saku';
      case JenisPenyaluran.lain:
        return 'Lain-lain';
    }
  }

  /// Apakah jenis ini berupa barang (bukan uang tunai ke anak)?
  bool get adalahBarang => this != JenisPenyaluran.uangSaku;

  static JenisPenyaluran fromString(String s) => JenisPenyaluran.values
      .firstWhere((e) => e.value == s.toUpperCase(), orElse: () => JenisPenyaluran.lain);
}

class Penyaluran {
  final int? id;
  final int anakId;
  final String tanggal; // ISO-8601 YYYY-MM-DD
  final JenisPenyaluran jenis;
  final String keterangan; // nama toko/penjahit, bulan uang saku, dll.
  final int nominal; // Rupiah, disimpan sebagai integer
  final String? penerima; // Wali kelas / orang tua (untuk uang saku)
  final int? transaksiKasId; // FK ke transaksi_kas.id, diisi otomatis

  const Penyaluran({
    this.id,
    required this.anakId,
    required this.tanggal,
    required this.jenis,
    required this.keterangan,
    required this.nominal,
    this.penerima,
    this.transaksiKasId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'anak_id': anakId,
      'tanggal': tanggal,
      'jenis': jenis.value,
      'keterangan': keterangan,
      'nominal': nominal,
      'penerima': penerima,
      'transaksi_kas_id': transaksiKasId,
    };
  }

  factory Penyaluran.fromMap(Map<String, dynamic> map) {
    return Penyaluran(
      id: map['id'] as int?,
      anakId: map['anak_id'] as int,
      tanggal: map['tanggal'] as String,
      jenis: JenisPenyaluranX.fromString(map['jenis'] as String),
      keterangan: map['keterangan'] as String,
      nominal: map['nominal'] as int,
      penerima: map['penerima'] as String?,
      transaksiKasId: map['transaksi_kas_id'] as int?,
    );
  }

  Penyaluran copyWith({int? id, int? transaksiKasId}) {
    return Penyaluran(
      id: id ?? this.id,
      anakId: anakId,
      tanggal: tanggal,
      jenis: jenis,
      keterangan: keterangan,
      nominal: nominal,
      penerima: penerima,
      transaksiKasId: transaksiKasId ?? this.transaksiKasId,
    );
  }
}
