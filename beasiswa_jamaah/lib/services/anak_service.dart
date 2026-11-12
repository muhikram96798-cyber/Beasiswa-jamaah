// Service: AnakService
// Menangani operasi database untuk Anak Penerima Beasiswa.

import 'package:sqflite/sqflite.dart';
import '../models/anak.dart';
import '../utils/inisial_helper.dart';
import 'database_service.dart';

class AnakService {
  final DatabaseService _dbService;

  AnakService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  Future<int> tambahAnak(Anak anak) async {
    final db = await _dbService.database;
    return await db.insert(
      'anak',
      anak.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateAnak(Anak anak) async {
    final db = await _dbService.database;
    return await db.update(
      'anak',
      anak.toMap(),
      where: 'id = ?',
      whereArgs: [anak.id],
    );
  }

  Future<int> hapusAnak(int id) async {
    final db = await _dbService.database;
    return await db.transaction<int>((txn) async {
      // 1. Ambil semua penyaluran untuk anak ini
      final listPenyaluran = await txn.query(
        'penyaluran',
        where: 'anak_id = ?',
        whereArgs: [id],
      );

      final kasIds = listPenyaluran
          .map((item) => item['transaksi_kas_id'] as int?)
          .whereType<int>()
          .toList();

      // 1. Lepaskan relasi sumber_id di transaksi_kas agar seluruh pengeluaran kas
      //    yang sudah disalurkan tetap aman & tercatat di pembukuan kas masjid
      //    (dana yang sudah dikeluarkan secara riil tidak akan balik lagi ke kas saat anak dihapus).
      for (final kasId in kasIds) {
        await txn.update(
          'transaksi_kas',
          {'sumber_id': null},
          where: 'id = ?',
          whereArgs: [kasId],
        );
      }

      // 2. Hapus data penyaluran anak agar foreign key constraint terlepas
      await txn.delete(
        'penyaluran',
        where: 'anak_id = ?',
        whereArgs: [id],
      );

      // 3. Hapus data anak (pembukuan kas tetap utuh & aman, dana tidak bertambah secara keliru)
      return await txn.delete(
        'anak',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Anak>> getSemuaAnak({bool? hanyaAktif}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'anak',
      where: hanyaAktif == true ? 'aktif = 1' : null,
      orderBy: 'aktif DESC, kode_anak ASC',
    );
    return maps.map((e) => Anak.fromMap(e)).toList();
  }

  Future<Anak?> getAnakById(int id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'anak',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Anak.fromMap(maps.first);
  }

  Future<String> generateKodeBaru() async {
    final db = await _dbService.database;
    final maps = await db.query('anak', columns: ['kode_anak']);
    final kodeYangAda = maps.map((e) => e['kode_anak'] as String).toList();
    return buatKodeAnak(kodeYangAda);
  }
}
