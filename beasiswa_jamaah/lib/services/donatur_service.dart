// Service: DonaturService
// Menangani operasi database untuk Donatur dan Iuran.
// Menjamin setiap pencatatan iuran otomatis masuk ke kas (satu sumber data).

import 'package:sqflite/sqflite.dart';
import '../models/donatur.dart';
import '../models/iuran.dart';
import '../models/transaksi_kas.dart';
import 'database_service.dart';

class DonaturService {
  final DatabaseService _dbService;

  DonaturService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  static const List<String> daftarNamaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> singkatanBulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String getNamaBulan(int bulan) {
    if (bulan < 1 || bulan > 12) return 'Bulan $bulan';
    return daftarNamaBulan[bulan - 1];
  }

  static String getSingkatanBulan(int bulan) {
    if (bulan < 1 || bulan > 12) return 'B$bulan';
    return singkatanBulan[bulan - 1];
  }

  // ─── CRUD Donatur ────────────────────────────────────────────────────────

  Future<int> tambahDonatur(Donatur donatur) async {
    final db = await _dbService.database;
    return await db.insert(
      'donatur',
      donatur.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateDonatur(Donatur donatur) async {
    final db = await _dbService.database;
    return await db.update(
      'donatur',
      donatur.toMap(),
      where: 'id = ?',
      whereArgs: [donatur.id],
    );
  }

  Future<int> hapusDonatur(int id) async {
    final db = await _dbService.database;
    return await db.transaction((txn) async {
      // Ambil semua iuran donatur ini untuk menghapus transaksi kas terkait
      final listIuran = await txn.query(
        'iuran',
        where: 'donatur_id = ?',
        whereArgs: [id],
      );

      for (final item in listIuran) {
        final kasId = item['transaksi_kas_id'] as int?;
        if (kasId != null) {
          await txn.delete(
            'transaksi_kas',
            where: 'id = ?',
            whereArgs: [kasId],
          );
        }
      }

      await txn.delete(
        'iuran',
        where: 'donatur_id = ?',
        whereArgs: [id],
      );

      return await txn.delete(
        'donatur',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Donatur>> getSemuaDonatur({bool? hanyaAktif}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'donatur',
      where: hanyaAktif == true ? 'status_aktif = 1' : null,
      orderBy: 'status_aktif DESC, nama_keluarga ASC',
    );
    return maps.map((e) => Donatur.fromMap(e)).toList();
  }

  Future<Donatur?> getDonaturById(int id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'donatur',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Donatur.fromMap(maps.first);
  }

  // ─── Pencatatan Iuran dan Kas Otomatis ─────────────────────────────────────

  /// Catat iuran donatur untuk bulan dan tahun ajaran tertentu.
  /// Secara otomatis mencatat transaksi kas masuk kategori IURAN.
  Future<Iuran> catatIuran({
    required int donaturId,
    required int bulan,
    required int tahunAjaran,
    required int nominal,
    required String tanggalBayar,
  }) async {
    final db = await _dbService.database;

    return await db.transaction<Iuran>((txn) async {
      // 1. Cek apakah sudah pernah bayar untuk bulan & tahun ini
      final existing = await txn.query(
        'iuran',
        where: 'donatur_id = ? AND bulan = ? AND tahun_ajaran = ?',
        whereArgs: [donaturId, bulan, tahunAjaran],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw StateError(
          'Iuran bulan ${getNamaBulan(bulan)} $tahunAjaran sudah pernah dicatat.',
        );
      }

      // 2. Ambil data donatur untuk keterangan kas
      final donaturMaps = await txn.query(
        'donatur',
        where: 'id = ?',
        whereArgs: [donaturId],
        limit: 1,
      );
      final namaKeluarga = donaturMaps.isNotEmpty
          ? (donaturMaps.first['nama_keluarga'] as String)
          : 'Donatur #$donaturId';

      final keteranganKas =
          'Iuran ${getNamaBulan(bulan)} $tahunAjaran - $namaKeluarga';

      // 3. Masukkan ke transaksi_kas (tipe MASUK, kategori IURAN)
      final kasId = await txn.insert('transaksi_kas', {
        'tanggal': tanggalBayar,
        'tipe': TipeTransaksi.masuk.value,
        'kategori': KategoriTransaksi.iuran.value,
        'keterangan': keteranganKas,
        'nominal': nominal,
        'sumber_id': null, // Akan diupdate setelah iuran dibuat
        'menggunakan_cadangan': 0,
      });

      // 4. Masukkan ke tabel iuran
      final iuranId = await txn.insert('iuran', {
        'donatur_id': donaturId,
        'bulan': bulan,
        'tahun_ajaran': tahunAjaran,
        'nominal': nominal,
        'tanggal_bayar': tanggalBayar,
        'transaksi_kas_id': kasId,
      });

      // 5. Update sumber_id pada transaksi_kas
      await txn.update(
        'transaksi_kas',
        {'sumber_id': iuranId},
        where: 'id = ?',
        whereArgs: [kasId],
      );

      return Iuran(
        id: iuranId,
        donaturId: donaturId,
        bulan: bulan,
        tahunAjaran: tahunAjaran,
        nominal: nominal,
        tanggalBayar: tanggalBayar,
        transaksiKasId: kasId,
      );
    });
  }

  /// Batalkan / hapus pembayaran iuran.
  /// Otomatis menghapus entri kas terkait.
  Future<void> batalIuran(int iuranId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      final iuranMaps = await txn.query(
        'iuran',
        where: 'id = ?',
        whereArgs: [iuranId],
        limit: 1,
      );

      if (iuranMaps.isEmpty) return;

      final kasId = iuranMaps.first['transaksi_kas_id'] as int?;
      if (kasId != null) {
        await txn.delete(
          'transaksi_kas',
          where: 'id = ?',
          whereArgs: [kasId],
        );
      }

      await txn.delete(
        'iuran',
        where: 'id = ?',
        whereArgs: [iuranId],
      );
    });
  }

  /// Ambil semua iuran pada tahun ajaran tertentu
  Future<List<Iuran>> getIuranByTahun(int tahunAjaran) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'iuran',
      where: 'tahun_ajaran = ?',
      whereArgs: [tahunAjaran],
      orderBy: 'bulan ASC, tanggal_bayar ASC',
    );
    return maps.map((e) => Iuran.fromMap(e)).toList();
  }

  /// Ambil iuran untuk satu donatur pada tahun ajaran tertentu
  Future<List<Iuran>> getIuranByDonatur(int donaturId, int tahunAjaran) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'iuran',
      where: 'donatur_id = ? AND tahun_ajaran = ?',
      whereArgs: [donaturId, tahunAjaran],
      orderBy: 'bulan ASC',
    );
    return maps.map((e) => Iuran.fromMap(e)).toList();
  }
}
