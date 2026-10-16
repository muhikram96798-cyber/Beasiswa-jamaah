// Model: Donatur
// Menyimpan data keluarga donatur dan nominal iuran bulanan mereka.

class Donatur {
  final int? id;
  final String namaKeluarga;
  final int nominalIuran; // Rupiah bulanan, disimpan sebagai integer
  final bool statusAktif;
  final String tanggalDaftar; // ISO-8601 YYYY-MM-DD
  final String? keterangan;

  const Donatur({
    this.id,
    required this.namaKeluarga,
    required this.nominalIuran,
    this.statusAktif = true,
    required this.tanggalDaftar,
    this.keterangan,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_keluarga': namaKeluarga,
      'nominal_iuran': nominalIuran,
      'status_aktif': statusAktif ? 1 : 0,
      'tanggal_daftar': tanggalDaftar,
      'keterangan': keterangan,
    };
  }

  factory Donatur.fromMap(Map<String, dynamic> map) {
    return Donatur(
      id: map['id'] as int?,
      namaKeluarga: map['nama_keluarga'] as String,
      nominalIuran: map['nominal_iuran'] as int,
      statusAktif: (map['status_aktif'] as int) == 1,
      tanggalDaftar: map['tanggal_daftar'] as String,
      keterangan: map['keterangan'] as String?,
    );
  }

  Donatur copyWith({
    int? id,
    String? namaKeluarga,
    int? nominalIuran,
    bool? statusAktif,
    String? tanggalDaftar,
    String? keterangan,
  }) {
    return Donatur(
      id: id ?? this.id,
      namaKeluarga: namaKeluarga ?? this.namaKeluarga,
      nominalIuran: nominalIuran ?? this.nominalIuran,
      statusAktif: statusAktif ?? this.statusAktif,
      tanggalDaftar: tanggalDaftar ?? this.tanggalDaftar,
      keterangan: keterangan ?? this.keterangan,
    );
  }
}
