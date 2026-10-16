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
    return await db.delete(
      'anak',
      where: 'id = ?',
      whereArgs: [id],
    );
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
