// Model: Pengaturan
// Semua nilai yang bisa diubah oleh pengurus disimpan di sini sebagai
// key-value. Nilai di-cast sesuai kebutuhan saat dibaca.

/// Kunci-kunci yang digunakan di tabel pengaturan
class PengaturanKey {
  // Biaya program per jenjang per tahun (sudah termasuk cadangan 10%)
  static const String biayaSd = 'biaya_sd';
  static const String biayaSmp = 'biaya_smp';
  static const String biayaSma = 'biaya_sma';

  // Estimasi PIP per jenjang per tahun
  static const String pipSd = 'pip_sd';
  static const String pipSmp = 'pip_smp';
  static const String pipSma = 'pip_sma';

  // Rentang iuran donatur (Rupiah)
  static const String iuranMin = 'iuran_min';
  static const String iuranMax = 'iuran_max';

  // Persentase dana cadangan dari total pemasukan (default: 10)
  static const String pctCadangan = 'pct_cadangan';

  // Bobot skor seleksi anak (total harus = 100)
  static const String bobotEkonomi = 'bobot_ekonomi';
  static const String bobotYatim = 'bobot_yatim';
  static const String bobotSaudara = 'bobot_saudara';
  static const String bobotKip = 'bobot_kip';

  // Indikator manual: jumlah anak putus sekolah (target: 0)
  static const String putusSekolah = 'putus_sekolah';

  // Tahun ajaran yang sedang aktif ditampilkan
  static const String tahunAjaranAktif = 'tahun_ajaran_aktif';

  // Hash PIN pengurus (kosong = belum diset, mode lihat saja)
  static const String pinHash = 'pin_hash';

  /// Nilai default untuk seeding database pertama kali
  static Map<String, String> get defaults => {
        biayaSd: '2310000',
        biayaSmp: '3575000',
        biayaSma: '4785000',
        pipSd: '450000',
        pipSmp: '750000',
        pipSma: '1800000',
        iuranMin: '20000',
        iuranMax: '30000',
        pctCadangan: '10',
        bobotEkonomi: '40',
        bobotYatim: '30',
        bobotSaudara: '15',
        bobotKip: '15',
        putusSekolah: '0',
        tahunAjaranAktif: '${DateTime.now().year}',
        pinHash: '',
      };
}

class Pengaturan {
  final String kunci;
  final String nilai;

  const Pengaturan({required this.kunci, required this.nilai});

  int get nilaiInt => int.tryParse(nilai) ?? 0;
  double get nilaiDouble => double.tryParse(nilai) ?? 0.0;
  bool get nilaiIsEmpty => nilai.isEmpty;

  Map<String, dynamic> toMap() => {'kunci': kunci, 'nilai': nilai};

  factory Pengaturan.fromMap(Map<String, dynamic> map) {
    return Pengaturan(
      kunci: map['kunci'] as String,
      nilai: map['nilai'] as String,
    );
  }
}
