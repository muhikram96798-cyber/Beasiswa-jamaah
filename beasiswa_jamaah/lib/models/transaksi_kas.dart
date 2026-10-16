// Model: TransaksiKas
// Setiap pemasukan dan pengeluaran kas dicatat di sini.
// Iuran dan penyaluran dibuat otomatis dari flow masing-masing,
// tidak perlu input manual ganda.

/// Tipe arah uang
enum TipeTransaksi { masuk, keluar }

/// Kategori transaksi
enum KategoriTransaksi {
  iuran,
  infak,
  donasi,
  perlengkapan,
  uangSaku,
  caiCadangan, // penggunaan dana cadangan
  lain,
}

extension TipeTransaksiX on TipeTransaksi {
  String get value => name.toUpperCase();
  static TipeTransaksi fromString(String s) =>
      TipeTransaksi.values.firstWhere((e) => e.value == s.toUpperCase());
}

extension KategoriTransaksiX on KategoriTransaksi {
  String get value {
    switch (this) {
      case KategoriTransaksi.iuran:
        return 'IURAN';
      case KategoriTransaksi.infak:
        return 'INFAK';
      case KategoriTransaksi.donasi:
        return 'DONASI';
      case KategoriTransaksi.perlengkapan:
        return 'PERLENGKAPAN';
      case KategoriTransaksi.uangSaku:
        return 'UANG_SAKU';
      case KategoriTransaksi.caiCadangan:
        return 'CAI_CADANGAN';
      case KategoriTransaksi.lain:
        return 'LAIN';
    }
  }

  String get label {
    switch (this) {
      case KategoriTransaksi.iuran:
        return 'Iuran Donatur';
      case KategoriTransaksi.infak:
        return 'Infak';
      case KategoriTransaksi.donasi:
        return 'Donasi';
      case KategoriTransaksi.perlengkapan:
        return 'Perlengkapan Anak';
      case KategoriTransaksi.uangSaku:
        return 'Uang Saku';
      case KategoriTransaksi.caiCadangan:
        return 'Pencairan Dana Cadangan';
      case KategoriTransaksi.lain:
        return 'Lain-lain';
    }
  }

  static KategoriTransaksi fromString(String s) => KategoriTransaksi.values
      .firstWhere((e) => e.value == s.toUpperCase(), orElse: () => KategoriTransaksi.lain);
}

class TransaksiKas {
  final int? id;
  final String tanggal; // ISO-8601 YYYY-MM-DD
  final TipeTransaksi tipe;
  final KategoriTransaksi kategori;
  final String keterangan;
  final int nominal; // Rupiah positif, disimpan sebagai integer
  final int? sumberId; // FK ke iuran.id atau penyaluran.id (nullable)
  final bool menggunakanCadangan; // true jika transaksi ini mencairkan dana cadangan

  const TransaksiKas({
    this.id,
    required this.tanggal,
    required this.tipe,
    required this.kategori,
    required this.keterangan,
    required this.nominal,
    this.sumberId,
    this.menggunakanCadangan = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': tanggal,
      'tipe': tipe.value,
      'kategori': kategori.value,
      'keterangan': keterangan,
      'nominal': nominal,
      'sumber_id': sumberId,
      'menggunakan_cadangan': menggunakanCadangan ? 1 : 0,
    };
  }

  factory TransaksiKas.fromMap(Map<String, dynamic> map) {
    return TransaksiKas(
      id: map['id'] as int?,
      tanggal: map['tanggal'] as String,
      tipe: TipeTransaksiX.fromString(map['tipe'] as String),
      kategori: KategoriTransaksiX.fromString(map['kategori'] as String),
      keterangan: map['keterangan'] as String,
      nominal: map['nominal'] as int,
      sumberId: map['sumber_id'] as int?,
      menggunakanCadangan: (map['menggunakan_cadangan'] as int? ?? 0) == 1,
    );
  }
}
