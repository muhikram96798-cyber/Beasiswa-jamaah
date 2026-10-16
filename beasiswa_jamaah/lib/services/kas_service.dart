// Service: KasService
// Mengelola transaksi kas bersama, penghitungan saldo, dan dana cadangan 10%.

import 'package:sqflite/sqflite.dart';
import '../models/transaksi_kas.dart';
import 'database_service.dart';

class RingkasanKas {
  final int totalPemasukan;
  final int totalPengeluaran;
  final int totalSaldo;
  final int danaCadanganWajib;
  final int danaCadanganTerpakai;
  final int danaCadanganTersedia;
  final int saldoBisaDipakai;
  final int persentaseCadangan;

  const RingkasanKas({
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.totalSaldo,
    required this.danaCadanganWajib,
    required this.danaCadanganTerpakai,
    required this.danaCadanganTersedia,
    required this.saldoBisaDipakai,
    this.persentaseCadangan = 10,
  });

  /// Factory untuk menghitung saldo dan cadangan dari daftar transaksi
  factory RingkasanKas.hitung(
    List<TransaksiKas> daftarTransaksi, {
    int persentaseCadangan = 10,
  }) {
    int totalPemasukan = 0;
    int totalPengeluaran = 0;
    int cadanganTerpakai = 0;

    for (final t in daftarTransaksi) {
      if (t.tipe == TipeTransaksi.masuk) {
        totalPemasukan += t.nominal;
      } else {
        totalPengeluaran += t.nominal;
        if (t.menggunakanCadangan) {
          cadanganTerpakai += t.nominal;
        }
      }
    }

    final totalSaldo = totalPemasukan - totalPengeluaran;

    // Dana cadangan dihitung otomatis dari total pemasukan (default 10%)
    final cadanganWajib = (totalPemasukan * (persentaseCadangan / 100)).round();

    // Sisa cadangan yang masih utuh
    final sisaCadangan = cadanganWajib - cadanganTerpakai;

    // Cadangan tersedia tidak boleh melebihi sisa kas yang ada
    final cadanganTersedia =
        totalSaldo > 0 ? (sisaCadangan > totalSaldo ? totalSaldo : (sisaCadangan > 0 ? sisaCadangan : 0)) : 0;

    // Saldo yang bisa dipakai secara bebas untuk kegiatan beasiswa
    final saldoBisaDipakai = totalSaldo - cadanganTersedia;

    return RingkasanKas(
      totalPemasukan: totalPemasukan,
      totalPengeluaran: totalPengeluaran,
      totalSaldo: totalSaldo,
      danaCadanganWajib: cadanganWajib,
      danaCadanganTerpakai: cadanganTerpakai,
      danaCadanganTersedia: cadanganTersedia,
      saldoBisaDipakai: saldoBisaDipakai > 0 ? saldoBisaDipakai : 0,
      persentaseCadangan: persentaseCadangan,
    );
  }
}

class KasService {
  final DatabaseService _dbService;

  KasService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  /// Ambil semua transaksi kas, diurutkan dari yang terbaru
  Future<List<TransaksiKas>> getSemuaTransaksi({
    String? tipe,
    int? limit,
  }) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi_kas',
      where: tipe != null ? 'tipe = ?' : null,
      whereArgs: tipe != null ? [tipe] : null,
      orderBy: 'tanggal DESC, id DESC',
      limit: limit,
    );
    return maps.map((e) => TransaksiKas.fromMap(e)).toList();
  }

  /// Hitung ringkasan kas secara otomatis
  Future<RingkasanKas> getRingkasanKas({int persentaseCadangan = 10}) async {
    final semua = await getSemuaTransaksi();
    return RingkasanKas.hitung(semua, persentaseCadangan: persentaseCadangan);
  }

  /// Tambah transaksi manual (infak, donasi lain, kas sosial, atau pengeluaran)
  /// dengan validasi ketat saldo kas:
  /// 1. Jika pengeluaran > totalSaldo: DITOLAK (kas tidak boleh negatif sama sekali).
  /// 2. Jika pengeluaran > saldoBisaDipakai: memerlukan flag menggunakanCadangan = true.
  Future<int> tambahTransaksi(
    TransaksiKas transaksi, {
    int persentaseCadangan = 10,
  }) async {
    final db = await _dbService.database;

    return await db.transaction<int>((txn) async {
      if (transaksi.tipe == TipeTransaksi.keluar) {
        // Ambil semua transaksi saat ini untuk menghitung saldo aktual
        final maps = await txn.query('transaksi_kas');
        final listSaatIni = maps.map((e) => TransaksiKas.fromMap(e)).toList();
        final ringkasan = RingkasanKas.hitung(
          listSaatIni,
          persentaseCadangan: persentaseCadangan,
        );

        // 1. Larangan total kas negatif
        if (transaksi.nominal > ringkasan.totalSaldo) {
          throw StateError(
            'Saldo total kas tidak mencukupi. Pengeluaran sebesar ${transaksi.nominal} akan membuat kas minus (Saldo total saat ini: ${ringkasan.totalSaldo}).',
          );
        }

        // 2. Jika melebihi saldo yang bisa dipakai, harus secara eksplisit menggunakan cadangan
        if (transaksi.nominal > ringkasan.saldoBisaDipakai &&
            !transaksi.menggunakanCadangan) {
          throw StateError(
            'Pengeluaran melebihi saldo yang bisa dipakai (${ringkasan.saldoBisaDipakai}). Memerlukan izin konfirmasi penggunaan dana cadangan.',
          );
        }
      }

      return await txn.insert(
        'transaksi_kas',
        transaksi.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  /// Hapus transaksi manual. Jika transaksi berasal dari iuran, beri tahu bahwa
  /// pembatalan sebaiknya dilakukan dari menu Donatur/Iuran.
  Future<void> hapusTransaksi(int id) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      final maps = await txn.query(
        'transaksi_kas',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return;

      final transaksi = TransaksiKas.fromMap(maps.first);

      // Jika iuran, hapus juga record iuran terkait agar satu sumber data
      if (transaksi.kategori == KategoriTransaksi.iuran &&
          transaksi.sumberId != null) {
        await txn.delete(
          'iuran',
          where: 'id = ?',
          whereArgs: [transaksi.sumberId],
        );
      }

      // Jika penyaluran, hapus juga record penyaluran terkait
      if ((transaksi.kategori == KategoriTransaksi.perlengkapan ||
              transaksi.kategori == KategoriTransaksi.uangSaku) &&
          transaksi.sumberId != null) {
        await txn.delete(
          'penyaluran',
          where: 'id = ?',
          whereArgs: [transaksi.sumberId],
        );
      }

      await txn.delete(
        'transaksi_kas',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
