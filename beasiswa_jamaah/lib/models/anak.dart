// Model: Anak
// Data penerima beasiswa. Nama lengkap hanya tampil di layar detail
// (mode pengurus). Laporan dan daftar menggunakan nama_samaran dan kode_anak.

/// Jenjang pendidikan
enum Jenjang { sd, smp, sma }

extension JenjangX on Jenjang {
  String get value => name.toUpperCase();
  String get label {
    switch (this) {
      case Jenjang.sd:
        return 'SD';
      case Jenjang.smp:
        return 'SMP';
      case Jenjang.sma:
        return 'SMA';
    }
  }

  static Jenjang fromString(String s) =>
      Jenjang.values.firstWhere((e) => e.value == s.toUpperCase());
}

/// Status keluarga anak
enum StatusYatim { lengkap, yatim, piatu, yatimPiatu }

extension StatusYatimX on StatusYatim {
  String get value {
    switch (this) {
      case StatusYatim.lengkap:
        return 'LENGKAP';
      case StatusYatim.yatim:
        return 'YATIM';
      case StatusYatim.piatu:
        return 'PIATU';
      case StatusYatim.yatimPiatu:
        return 'YATIM_PIATU';
    }
  }

  String get label {
    switch (this) {
      case StatusYatim.lengkap:
        return 'Orang tua lengkap';
      case StatusYatim.yatim:
        return 'Yatim (ayah meninggal)';
      case StatusYatim.piatu:
        return 'Piatu (ibu meninggal)';
      case StatusYatim.yatimPiatu:
        return 'Yatim piatu';
    }
  }

  static StatusYatim fromString(String s) =>
      StatusYatim.values.firstWhere((e) => e.value == s.toUpperCase());
}

/// Kondisi ekonomi keluarga
enum KondisiEkonomi { sangatKurang, kurang, cukup }

extension KondisiEkonomiX on KondisiEkonomi {
  String get value {
    switch (this) {
      case KondisiEkonomi.sangatKurang:
        return 'SANGAT_KURANG';
      case KondisiEkonomi.kurang:
        return 'KURANG';
      case KondisiEkonomi.cukup:
        return 'CUKUP';
    }
  }

  String get label {
    switch (this) {
      case KondisiEkonomi.sangatKurang:
        return 'Sangat kurang';
      case KondisiEkonomi.kurang:
        return 'Kurang';
      case KondisiEkonomi.cukup:
        return 'Cukup';
    }
  }

  static KondisiEkonomi fromString(String s) =>
      KondisiEkonomi.values.firstWhere((e) => e.value == s.toUpperCase());
}

/// Status KIP/PIP anak
/// - sudahMenerima: sudah mendapat PIP → dana kebutuhan dikurangi estimasi PIP
/// - sedangDiurus: dalam proses pendaftaran
/// - belum: belum punya KIP/PIP sama sekali → skor seleksi lebih tinggi
enum StatusPip { sudahMenerima, sedangDiurus, belum }

extension StatusPipX on StatusPip {
  String get value {
    switch (this) {
      case StatusPip.sudahMenerima:
        return 'SUDAH_MENERIMA';
      case StatusPip.sedangDiurus:
        return 'SEDANG_DIURUS';
      case StatusPip.belum:
        return 'BELUM';
    }
  }

  String get label {
    switch (this) {
      case StatusPip.sudahMenerima:
        return 'Sudah menerima PIP';
      case StatusPip.sedangDiurus:
        return 'Sedang diurus';
      case StatusPip.belum:
        return 'Belum / tidak ada';
    }
  }

  static StatusPip fromString(String s) =>
      StatusPip.values.firstWhere((e) => e.value == s.toUpperCase());
}

class Anak {
  final int? id;
  final String kodeAnak; // contoh: "A-01", unik internal
  final String namaLengkap; // RAHASIA — hanya layar detail mode pengurus
  final String namaSamaran; // contoh: "A.F. - SD Kelas 3"
  final Jenjang jenjang;
  final int kelas; // 1–6 (SD), 7–9 (SMP), 10–12 (SMA)
  final StatusYatim statusYatim;
  final int jumlahSaudara;
  final KondisiEkonomi kondisiEkonomi;
  final StatusPip statusPip;
  final bool buruhTani; // Apakah dari keluarga buruh tani
  final String? namaWali; // Wali kelas / orang tua penerima uang saku
  final String tanggalMasuk; // ISO-8601 YYYY-MM-DD
  final bool aktif;
  final String? keterangan;

  const Anak({
    this.id,
    required this.kodeAnak,
    required this.namaLengkap,
    required this.namaSamaran,
    required this.jenjang,
    required this.kelas,
    required this.statusYatim,
    required this.jumlahSaudara,
    required this.kondisiEkonomi,
    required this.statusPip,
    this.buruhTani = false,
    this.namaWali,
    required this.tanggalMasuk,
    this.aktif = true,
    this.keterangan,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'kode_anak': kodeAnak,
      'nama_lengkap': namaLengkap,
      'nama_samaran': namaSamaran,
      'jenjang': jenjang.value,
      'kelas': kelas,
      'status_yatim': statusYatim.value,
      'jumlah_saudara': jumlahSaudara,
      'kondisi_ekonomi': kondisiEkonomi.value,
      'status_pip': statusPip.value,
      'buruh_tani': buruhTani ? 1 : 0,
      'nama_wali': namaWali,
      'tanggal_masuk': tanggalMasuk,
      'aktif': aktif ? 1 : 0,
      'keterangan': keterangan,
    };
  }

  factory Anak.fromMap(Map<String, dynamic> map) {
    return Anak(
      id: map['id'] as int?,
      kodeAnak: map['kode_anak'] as String,
      namaLengkap: map['nama_lengkap'] as String,
      namaSamaran: map['nama_samaran'] as String,
      jenjang: JenjangX.fromString(map['jenjang'] as String),
      kelas: map['kelas'] as int,
      statusYatim: StatusYatimX.fromString(map['status_yatim'] as String),
      jumlahSaudara: map['jumlah_saudara'] as int,
      kondisiEkonomi: KondisiEkonomiX.fromString(map['kondisi_ekonomi'] as String),
      statusPip: StatusPipX.fromString(map['status_pip'] as String),
      buruhTani: (map['buruh_tani'] as int? ?? 0) == 1,
      namaWali: map['nama_wali'] as String?,
      tanggalMasuk: map['tanggal_masuk'] as String,
      aktif: (map['aktif'] as int) == 1,
      keterangan: map['keterangan'] as String?,
    );
  }

  Anak copyWith({
    int? id,
    String? kodeAnak,
    String? namaLengkap,
    String? namaSamaran,
    Jenjang? jenjang,
    int? kelas,
    StatusYatim? statusYatim,
    int? jumlahSaudara,
    KondisiEkonomi? kondisiEkonomi,
    StatusPip? statusPip,
    bool? buruhTani,
    String? namaWali,
    String? tanggalMasuk,
    bool? aktif,
    String? keterangan,
  }) {
    return Anak(
      id: id ?? this.id,
      kodeAnak: kodeAnak ?? this.kodeAnak,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      namaSamaran: namaSamaran ?? this.namaSamaran,
      jenjang: jenjang ?? this.jenjang,
      kelas: kelas ?? this.kelas,
      statusYatim: statusYatim ?? this.statusYatim,
      jumlahSaudara: jumlahSaudara ?? this.jumlahSaudara,
      kondisiEkonomi: kondisiEkonomi ?? this.kondisiEkonomi,
      statusPip: statusPip ?? this.statusPip,
      buruhTani: buruhTani ?? this.buruhTani,
      namaWali: namaWali ?? this.namaWali,
      tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
      aktif: aktif ?? this.aktif,
      keterangan: keterangan ?? this.keterangan,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Anak) return false;
    if (id != null && other.id != null) {
      return id == other.id;
    }
    return id == other.id &&
        kodeAnak == other.kodeAnak &&
        namaLengkap == other.namaLengkap;
  }

  @override
  int get hashCode =>
      id != null ? id.hashCode : Object.hash(kodeAnak, namaLengkap);
}
